# myExperiment: app/controllers/research_objects_controller.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'curl'
require 'wf4ever/rosrs_client'

class ResearchObjectsController < ApplicationController

  include ApplicationHelper

  before_filter :find_research_object,  :only => [:show, :edit, :update, :resource_show]
  before_filter :find_research_objects, :only => [:all]
  
  # GET /research_objects
  def index
    respond_to do |format|
      format.html {

        @pivot, problem = calculate_pivot(

            :pivot_options  => Conf.pivot_options,
            :params         => params,
            :user           => current_user,
            :search_models  => [ResearchObject],
            :search_limit   => Conf.max_search_size,

            :locked_filters => { 'CATEGORY' => 'ResearchObject' },

            :active_filters => ["CATEGORY", "TYPE_ID", "TAG_ID", "USER_ID",
                                "LICENSE_ID", "GROUP_ID", "WSDL_ENDPOINT",
                                "CURATION_EVENT", "SERVICE_PROVIDER",
                                "SERVICE_COUNTRY", "SERVICE_STATUS"])

        flash.now[:error] = problem if problem

        @query = params[:query]
        @query_type = 'research_objects'

        # index.rhtml
      }
    end
  end
  
  # GET /research_objects/1
  def show

    @manifest = @contributable.manifest

    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /research_objects/new
  def new
    @research_object = ResearchObject.new
  end
  
  # GET /research_objects/1/edit
  def edit
    @research_object = @contributable
  end

  # POST /research_objects
  def create

    if !params[:research_object].is_a?(Hash)
      error("Research Object is invalid", "is invalid")
      return
    end

    ro_params = params[:research_object]

    # get url (if provided)
    url = ro_params[:url] if ro_params[:url].is_a?(String) && !ro_params[:url].empty?

    # get request body (if provided)
    file = request.raw_post if request.raw_post != nil && request.env["CONTENT_TYPE"] == "text/turtle"

    # get uploaded file (if provided)
    file = ro_params[:data].read if ro_params[:data].respond_to?(:read)

    if !url && !file
      error("You must either specify a URL or upload a Research Object", "not found")
      return
    end

    if url && file
      error("You specified a URL and uploaded a Research Object", "is invalid")
      return
    end

    if url
      begin
        curl = Curl::Easy.new(url)
        
        curl.follow_location = true

        curl.http_get
        throw Exception if curl.response_code != 200
        research_object = curl.body_str
      rescue
        error("Problem retrieving content from URL (HTTP status #{curl.response_code})",
            "is invalid")
        return
      end
    else
      research_object = file
    end

    policy = Policy.new(:contributor => current_user, :name => 'auto', :share_mode => 0, :update_mode => 6)

    @research_object = ResearchObject.create(
        :contributor  => current_user,
        :contribution => Contribution.new(:policy => policy),
        :url          => url,
        :title        => ro_params[:title],
        :description  => ro_params[:description],
        :content_blob => ContentBlob.new(:data => research_object))

    @research_object.load_graph if @research_object.valid?

    respond_to do |format|
      format.html {
        if @research_object.new_record?
          render :action => "new"
        else
          redirect_to(@research_object)
        end
      }
    end
  end
  
  # PUT /research_objects/1
  def update
  end

  # DELETE /research_objects/1
  def destroy
  end

  # GET /research_objects/:id/resource/:resource_path
  def resource_show

#   resource_object = Statement.find(:first, :conditions => {
#       :research_object_id => @contributable.id,
#       :predicate_text => 'http://purl.org/wf4ever/ro#name',
#       :objekt_text => params[:path]})

#   raise ActiveRecord::RecordNotFound if resource_object.nil?

#   statements = Statement.find(:all, :conditions => {
#       :subject_text => resource_object.subject_text
#   })

    # Get annotations as merged graph.  This will be pulled from cache
    # eventually.

    session = ROSRS::Session.new(@contributable.url, Conf.rodl_bearer_token)

    @resuri = @contributable.resolve_resource_uri(params[:resource_path])

    @annotations = session.get_annotation_graph(@contributable.url, @resuri)

    @contributable.manifest.query([@resuri, nil, nil]).each do |statement|

      case statement.predicate.to_s
      when "http://purl.org/wf4ever/ro#name":      @manifest_name    = statement.object.to_s
      when "http://purl.org/dc/terms/created":     @manifest_created = Date.parse(statement.object.to_s)
      when "http://purl.org/dc/terms/creator":     @manifest_creator = statement.object.to_s
      when "http://purl.org/wf4ever/ro#checksum" : @manifest_md5     = statement.object.to_s
      when "http://purl.org/wf4ever/ro#filesize" : @manifest_size    = statement.object.to_s.to_i
      end

    end

    @annotations.query([@resuri, nil, nil]).each do |statement|

      case statement.predicate.to_s
      when "http://purl.org/dc/terms/title":       @title       = statement.object.to_s
      when "http://purl.org/dc/terms/description": @description = statement.object.to_s
      when "http://purl.org/dc/terms/creator":     @creator     = statement.object.to_s
      when "http://purl.org/dc/terms/created":     @created     = Date.parse(statement.object.to_s)
      end

    end

    render :resource_show
  end

  protected
  
  def find_research_objects
    @contributables = ResearchObject.find(:all, 
                       :order => "created_at DESC",
                       :page => { :size => 20, 
                       :current => params[:page] })
  end
  
  def find_research_object
    begin
      research_object = ResearchObject.find(params[:id])
      
      @contributable = research_object
      
      @contributable_entry_url = url_for :only_path => false,
                          :host => base_host,
                          :id => @contributable.id

      @contributable_label                = @contributable.title
      @contributable_path                 = research_object_path(@contributable)

    rescue ActiveRecord::RecordNotFound
      error("Research Object not found", "is invalid")
    end
  end
  
  private
  
  def error(notice, message, attr=:id)
    flash[:error] = notice
     (err = ResearchObject.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to research_objects_url }
    end
  end
end
