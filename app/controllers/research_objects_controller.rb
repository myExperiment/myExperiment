# myExperiment: app/controllers/research_objects_controller.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

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

    unless ro
      render :text => "Research Object not found", :status => 404
      return
    end

    respond_to do |format|
      format.html {
        redirect_to polymorphic_path(ro.context)
      }
      format.rdf { 
        redirect_to research_object_url(slug) + "/" + ResearchObject::MANIFEST_PATH, :status => 303
      }
      format.zip {
        redirect_to zipped_research_object_url(slug) + "/"
      }
    end
  end

  def download_zip

    slug = params[:id]
    slug = slug[0..-2] if slug.ends_with?("/")

    ro = ResearchObject.find_by_slug_and_version(slug, nil)

    unless ro
      render :text => "Research Object not found", :status => 404
      return
    end

    respond_to do |format|
      format.zip {
        zip_file_name = ro.generate_zip!
        send_file zip_file_name, :type => "application/zip", :disposition => 'attachment', :filename => "#{ro.slug}.zip"
      }
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

    send_data(ro.manifest_resource.content_blob.data, :type => "application/rdf+xml", :filename => ResearchObject::MANIFEST_PATH, :status => 201)
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

