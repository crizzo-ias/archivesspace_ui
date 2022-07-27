class AgentsTestController < ApplicationController
  skip_before_action :verify_authenticity_token

  def special
    solr_params = { "q" => "primary_type:agent_person OR primary_type:agent_family OR primary_type:agent_corporate_entity",
                    "fq" => "publish:true",
                    "rows" => 3,
                    "wt" => "json" }
    solr_results = archivesspace.solr(solr_params)
    results = solr_results["response"]
    pub_count = results["numFound"]
    if pub_count > 0
      Rails.logger.debug("We got #{pub_count} PUBLISHED ")
      Rails.logger.debug(results.pretty_inspect)
    end
    solr_params["fq"] = "publish:false"
    solr_results = archivesspace.solr(solr_params)
    unresults = solr_results["response"]
    unpubcount = unresults["numFound"]
    Rails.logger.debug("We got #{unpubcount} UNPUBLISHED")
    render "agents/special", locals: { :results => results, :pubcount => pub_count, :unpubcount => unpubcount }
  end
end
