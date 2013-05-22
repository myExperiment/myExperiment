require 'securerandom'

class ResearchObjectsController < ActionController::Base

  # GET /rodl
  def index

    uri_list = ""

    ResearchObject.all.each do |ro|
      uri_list << "#{research_object_url(ro.slug)}/\n"
    end

    send_data(uri_list, :type => 'text/uri-list')
  end

  # GET /rodl/:id
  def show

    slug = params[:id]
    slug = slug[0..-2] if slug.ends_with?("/")

    ro = ResearchObject.find_by_slug_and_version(slug, nil)

    if (ro)
      redirect_to research_object_url(slug) + "/" + ResearchObject::MANIFEST_PATH, :status => 303
    else
      render :text => "Research Object not found", :status => 404
    end
  end

  # POST /rodl
  def create
    
    current_user = User.find(1) # FIXME - hardcoded
    
    slug = request.headers["Slug"]
    
    # Remove trailing slash if given.

    slug = slug[0..-2] if slug.ends_with?("/")

    # If a research object exists with the slug then respond with 409 Conflict.

    if ResearchObject.find_by_slug_and_version(slug, nil)
      render :nothing => true, :status => 409
      return
    end

    # Create the research object with a blank manifest.  The blank manifest is
    # created so that when the manifest is aggregated it contains the
    # description of the manifest.

    ro_uri = research_object_url(slug) + "/"

    ro = ResearchObject.create(:slug => slug, :user => current_user)

    response.headers["Location"] = ro_uri

    send_data(ro.manifest_resource.data, :type => "application/rdf+xml", :filename => ResearchObject::MANIFEST_PATH, :status => 201)
  end

  # DELETE /rodl/:id
  def destroy

    ro = ResearchObject.find_by_slug_and_version(params[:id], nil)
    
    if ro
      ro.destroy
      render :nothing => true, :status => 204
    else
      render :text => "Research Object not found", :status => 404
    end
  end

  # PUT /rodl/:id
  def update
  end

end

