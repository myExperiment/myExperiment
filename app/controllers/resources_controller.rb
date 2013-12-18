# myExperiment: app/controllers/resources_controller.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require 'securerandom'

class ResourcesController < ApplicationController

  include ResearchObjectsHelper

# before_filter :dump_request_to_log
# after_filter :dump_response_to_log
 
  def dump_to_log(thing, type)
    # Dump headers

    logger.info "---- #{type} headers ----------------------------------"
    thing.headers.each do |header, value|
      if header.starts_with?("HTTP_")
          logger.info sprintf("%s: %s\n", header.sub(/^HTTP_/, "").downcase, value)
      end
    end

    logger.info "Content-Type: " + thing.content_type.to_s
    if thing.body
      logger.info "---- #{type} body  ------------------------------------"
      if thing.body.kind_of?(String)
        logger.info thing.body
      else
        logger.info thing.body.read
        thing.body.rewind
      end
    end
    logger.info "---- #{type} end  ------------------------------------"

  end

  def dump_request_to_log
    dump_to_log(request, 'Request')
  end

  def dump_response_to_log
    dump_to_log(response, 'Response')
  end

  def show

    ro = ResearchObject.find_by_slug_and_version(params[:research_object_id], nil)

    unless ro
      render :text => "Research Object not found", :status => :not_found
      return
    end

    unless Authorization.check('view', ro, current_user)
      render_401("You are unauthorized to view this research object.")
      return
    end

    resource = ro.resources.find_by_path(params[:id])

    unless resource
      render :text => "Resource not found", :status => :not_found
      return
    end

    # FIXME: This needs to support 406 

    unless Authorization.check('view', resource, current_user)
      render_401("You are unauthorized to view this resource.")
      return
    end

    # FIXME: This needs to support 401/403 

    if resource.is_proxy
      if resource.proxy_for
        redirect_to resource.proxy_for.uri.to_s, :status => 303
      else
        redirect_to resource.proxy_for_path, :status => 303
      end
    else

      # Generate RDF on demand if required.

      if resource.content_blob.nil?
        resource.generate_graph!
        resource.reload
      end

      send_data(resource.content_blob.data, :type => resource.content_type)
    end
  end

  def post

    research_object = ResearchObject.find_by_slug_and_version(params[:research_object_id], nil)

    unless research_object
      render :text => "Research Object not found", :status => :not_found
      return
    end

    slug = request.headers["Slug"].gsub(" ", "%20") if request.headers["Slug"]

    status, reason, location, links, filename, changes = research_object.new_or_update_resource(
        :slug         => slug,
        :path         => params[:path],
        :content_type => request.content_type.to_s,
        :user_uri     => user_url(current_user),
        :data         => request.body.read,
        :links        => parse_links(request.headers))

    research_object.update_manifest! if status == :created

    response.headers["Location"] = location      if location.kind_of?(String)
    response.headers["Location"] = location.to_s if location.kind_of?(RDF::URI)

    if links.length > 0
      response.headers['Link'] = links.map do |link|
        "<#{link[:link].kind_of?(RDF::URI) ? link[:link].to_s : link[:link]}>; " +
        "rel=\"#{link[:rel].kind_of?(RDF::URI) ? link[:rel].to_s : link[:rel]}\""
      end
    end

    if status == :created

      graph = RDF::Graph.new

      changes.each do |change|
        graph << change.description
      end

      body = pretty_rdf_xml(render_rdf(graph))

      send_data body, :type => 'application/rdf+xml', :filename => filename, :status => :created
    else
      render :status => status, :text => reason
    end
  end

  def delete

    ro = ResearchObject.find_by_slug_and_version(params[:research_object_id], nil)

    unless ro
      render :text => "Research Object not found", :status => :not_found
      return
    end

    path = params[:id]

    if path == ResearchObject::MANIFEST_PATH
      render :text => "Cannot delete the manifest", :status => :forbidden
      return
    end

    resource = ro.resources.find_by_path(path)

    if resource.nil?
      render :text => "Resource not found", :status => :not_found
      return
    end

    # Delete the proxy if one exists for this resource.

    if resource.content_type == 'application/vnd.wf4ever.proxy'
      proxy = resource
      resource = Resource.find_by_path(resource.proxy_for_path)
    else
      proxy = Resource.find_by_proxy_for_path(resource.path)
    end

    proxy.destroy    if proxy
    resource.destroy if resource

    render :nothing => true, :status => :no_content    
  end

end
