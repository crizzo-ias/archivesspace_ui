require "pp"  # temporary, she hopes!
require "uri"

# sets up the AppConfig to conform to IAS's needs
AppConfig[:pui_hide][:repositories] = true
AppConfig[:pui_hide][:subjects] = false
AppConfig[:pui_hide][:agents] = false
AppConfig[:pui_hide][:accessions] = true
AppConfig[:pui_hide][:classifications] = false
AppConfig[:pui_branding_img] = "/assets/ias.png"
AppConfig[:pui_branding_img_alt_text] = "Institute for Advanced Study"
AppConfig[:pui_page_actions_print] = true

# page actions override
AppConfig[:pui_page_actions_cite] = true
AppConfig[:pui_page_actions_request] = true
AppConfig[:pui_page_actions_print] = true

# read in routes
my_routes = File.join(File.dirname(__FILE__), "routes.rb")

Plugins.extend_aspace_routes(my_routes)

## OVERRIDE VARIOUS METHODS/ ADD NEW METHODS
Rails.application.config.after_initialize do
  ##### BEGIN BLOCK TO FIX BUG IN ASPACE CORE #####
  # The code in this section is related to this issue in core ASpace: https://github.com/archivesspace/archivesspace/issues/2177
  # The issue has been resolved, but as of the 3.0.2RC on 8/9/21 has not made it into a release
  # When the commits listed in that issue have made it into the release that this plugin is running on
  # this code block can be removed

  module I18n
    def self.prioritize_plugins!
      self.load_path = self.load_path.reject { |p| p.match /plugins\// } + self.load_path.reject { |p| !p.match /plugins\// }
    end
  end

  I18n.prioritize_plugins!
  I18n.load_path = I18n.load_path.reject { |p| !p.match /frontend\// } + I18n.load_path.reject { |p| p.match /frontend\// }

  ##### END BLOCK TO FIX BUG IN ASPACE CORE #####

  # add "talk directly to solr"
  class ArchivesSpaceClient
    def solr(params)
      url = URI("#{AppConfig[:solr_url]}/select")
      url.query = URI.encode_www_form(params)
      results = do_search(url)
      results
    end

    # do an internal redirect? from https://coderwall.com/p/gghtkq/rails-internal-requests
    # commenting that out for now; just doing a redirect
    def internal_request(path, params = {})
      #      request_env = Rack::MockRequest.env_for(path, params: params.to_query) #.merge({
      #                                      'rack.session' => session  # remove if session is unavailable/undesired in request
      #                                                                                   })
      # Returns: [ status, headers, body ]
      #      Rails.application.routes.call(request_env)
      ActionController::Redirecting.redirect_to(path)
    end
  end

  class Record
    def get_this_components_id
      # We want the component_id for this specific object, and do not want to return it if
      # it's using an inherited id
      if json.include?("component_id_inherited")
        return ""
      end
      json.fetch("component_id", "")
    end
  end

  class Search
    def Search.get_boolean_opts
      if @@BooleanOpts.empty?
        @@BooleanOpts = %w(AND OR NOT).map { |opt|
          [I18n.t("advanced_search.operator.#{opt}"), opt]
        }
      end
      @@BooleanOpts
    end
  end

  # Override some assumed defaults in the core code
  Searchable.module_eval do
    alias_method :core_set_up_and_run_search, :set_up_and_run_search
    alias_method :core_set_up_advanced_search, :set_up_advanced_search
    alias_method :core_process_search_results, :process_search_results

    # override the resources#index faceting
    def set_up_and_run_search(default_types = [], default_facets = [], default_search_opts = {}, params = {})
      if default_types.length == 1 && default_types[0] == "resource"
        default_facets = %w{subjects}
      end
      unless default_types.blank?
        default_types.delete("agent")
        default_types.delete("subject")
      end
      core_set_up_and_run_search(default_types, default_facets, default_search_opts, params)
    end

    # we don't want to see agents or subjects in the search results, only in facets
    def set_up_advanced_search(default_types = [], default_facets = [], default_search_opts = {}, params = {})
      unless default_types.blank?
        default_types.delete("agent")
        default_types.delete("subject")
      end
      core_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
    end
  end
  # add a digital only action to the resources controller
  class ResourcesController
    def digital_only
      uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
      begin
        @criteria = {}
        @criteria["resolve[]"] = ["repository:id", "resource:id@compact_resource", "top_container_uri_u_sstr:id", "related_accession_uris:id", "digital_object_uris:id"]
        tree_root = archivesspace.get_raw_record(uri + "/tree/root") rescue nil
        @has_children = tree_root && tree_root["child_count"] > 0
        @has_containers = false
        @result = archivesspace.get_record(uri, @criteria)
        @repo_info = @result.repository_information
        @page_title = "#{I18n.t("resource._singular")}: #{strip_mixed_content(@result.display_string)}"
        @context = [{ :uri => @repo_info["top"]["uri"], :crumb => @repo_info["top"]["name"] }, { :uri => nil, :crumb => process_mixed_content(@result.display_string) }]
        get_digital_objects(uri, params)
        fill_request_info
      rescue RecordNotFound => bang
        @type = I18n.t("resource._singular")
        @page_title = I18n.t("errors.error_404", :type => @type)
        @uri = uri
        @back_url = request.referer || ""
        Rails.logger.debug("** NOT FOUND EXCEPTION: #{bang.pretty_inspect}")
        render "shared/not_found", :status => 404
      end
    end

    def get_digital_objects(uri, params)
      page = params.fetch(:page, "1")
      page = Integer(page)
      page_size = Integer(params.fetch(:page_size, AppConfig[:pui_search_results_page_size]))
      uri_prefix = "/repositories/#{params[:rid]}/digital_objects/"
      r = Regexp.new("#{uri_prefix}(\\d+)")
      @digital_objs = []
      @ids = params.fetch(:ids, "").split(",")
      if @ids.blank?
        #get an ordered list of all the archive records in the resource
        ordered_records = archivesspace.get_record("#{uri}/ordered_records").json.fetch("uris")
        # strip out the 'ref' value to get a list by uri
        refs = ordered_records.map { |u| u.fetch("ref") }
        # raise up the archival object link so we can sort on it
        dig_results = get_resource_digital_objects(uri, refs.length)
        dig_results["docs"].each do |doc|
          Rails.logger.debug("is there a linked instance uris? #{doc["uri"]} #{doc["title"]} #{doc["linked_instance_uris"].pretty_inspect}")
          if !doc["linked_instance_uris"].blank?
            doc["linked_instance_uris"].each do |link|
              if refs.include?(link)
                doc["ao_link"] = link
                break
              end
            end
          end
        end
        # sort the docs on the archival object link
        dig_results = dig_results["docs"].sort_by { |r| refs.index(r[:ao_link]) }
        # flatten to just uris
        dig_results = dig_results.map { |doc| doc["uri"] }
        # grab the ids
        @ids = dig_results.grep(r) { |u| r.match(u)[1] }
      end
      slice = @ids[(page - 1) * page_size, page_size]
      search_uris = slice.map { |id| "id:\"#{uri_prefix}#{id}\"" }.join(" OR ")
      begin
        set_up_search(["digital_object"], [], { "resolve[]" => ["repository:id", "resource:id@compact_resource", "ancestors:id@compact_resource"] }, {}, search_uris)
        @results = archivesspace.search(@query, 1, @criteria)
      rescue Exception => error
        flash[:error] = I18n.t("errors.unexpected_error")
        redirect_back(fallback_location: "/") and return
      end
      process_results(@results["results"], false)
      # sort by the ordered ao records
      @digital_objs = @results.records.sort_by { |res| slice.index(r.match(res.uri)[1]) }
      @pager = Pager.new("/repositories/#{params[:rid]}/resources/#{params[:id]}/digital_only", page, ((@ids.length % page_size == 0) ? @ids.length / page_size : (@ids.length / page_size) + 1))
    end
  end

  # add check for digital objects
  ResultInfo.module_eval do
    def fill_request_info
      @request = @result.request_item
      # looking for digital objects goes here
      begin
        @digital_count = get_resource_digital_objects(@request.request_uri, 1)["numFound"] || 0
        # we may have digital objects at the resource level
        #     results = get_resource_level_digital(@request.request_uri)
        #    @digital_count = @digital_count + (results["numFound"] || 0)
      rescue Exception => boom
        STDERR.puts "Error getting digital object count for #{@request.request_uri}: #{boom}"
        @has_digital = false
      end
      if @result.primary_type == "resource"
        resource = @result
      else @result.primary_type == "resource"
        resource_uri = @result.breadcrumb.map { |c| c[:uri] if c[:type] == "resource" }.compact
        unless resource_uri.blank?
        resource = archivesspace.get_record(resource_uri, {})
      end       end
      @request
    end

    # find all published digital objects for a resource EXCEPT at resource level
    def get_resource_digital_objects(res_id, size = 1)
      aos = get_aos_with_digital(res_id)
      dig_uris = []
      aos["docs"].each do |ao|
        dig_uris += ao["digital_object_uris"]
      end
      dig_uris = dig_uris.map { |u| "\"#{u}\"" }
      ids = "#{dig_uris.join(" OR ")}"
      solr_params = { "q" => "id:cat(#{ids})",
                      "fq" => "primary_type:digital_object AND publish:true",
                      "rows" => size,
                      "wt" => "json" }
      solr_results = archivesspace.solr(solr_params)
      results = solr_results["response"]
    end

    #types:pui_digital_object AND publish:true AND linked_instance_uris:"/repositories/2/resources/2"
    def get_resource_level_digital(res_id, size = 1)
      solr_params = { "q" => "types:pui_digital_object AND publish:true",
                      "fq" => "linked_instance_uris:\"#{res_id}\"",
                      "rows" => size,
                      "fl" => "id,uri",
                      "wt" => "json" }

      solr_results = archivesspace.solr(solr_params)
      solr_results["response"]
    end

    def get_aos_with_digital(res_id)
      solr_params = { "q" => 'digital_object_uris:[\"\" TO *] AND types:pui_archival_object AND publish:true',
                      "fq" => "resource:\"#{res_id}\"",
                      "fl" => "id,uri, digital_object_uris",
                      "wt" => "json" }
      solr_results = archivesspace.solr(solr_params)
      results = solr_results["response"]
    end
  end
  #
  # reassign page numbers for pagination
  class Pager
    Pager::PAGE_NUMBERS_TO_SHOW
    Pager::PAGE_NUMBERS_TO_SHOW = 5
  end
end
