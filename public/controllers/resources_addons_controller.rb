class ResourcesAddonsController < ApplicationController
  include ResultInfo
  helper_method :process_repo_info
  helper_method :process_subjects
  helper_method :process_agents

  skip_before_action :verify_authenticity_token

  # supporting digital object detection
  def digital_object_count
    repo_id = params.require(:rid)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    results = get_resource_digital_objects(res_id, 2)
    count = results["numFound"]
    # get any resource-level digital objects
    # results = get_resource_digital(res_id, 2)
    # count = count + results["numFound"]
    render(partial: "resources/digital_count", locals: { :count => count })
  end

  # display an object given a refid
  def refid
    redirect_from_reference("ref_id", params[:refid])
  end

  # display a digital object given a digital object id
  def digid
    redirect_from_reference("digital_object_id", params[:digid])
  end

  private

  # display a resource or object based on its id
  def redirect_from_reference(idtype, id)
    results = archivesspace.search("#{idtype}:#{id}")
    uri = nil
    unless results["total_hits"] == 0
      results = results["results"]
      uri = results[0]["uri"] if results[0]["publish"]
    end
    if uri
      redirect_to(uri)
      #     archivesspace.internal_request(uri)
    else
      render "shared/not_found", :status => 404
    end
  end
end
