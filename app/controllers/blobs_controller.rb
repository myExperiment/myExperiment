# myExperiment: app/controllers/blobs_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlobsController < ApplicationController

  include ApplicationHelper

  before_filter :login_required, :except => [:index, :show, :download, :named_download, :named_download_with_version, :statistics, :search, :auto_complete]

  before_filter :find_blob_auth, :except => [:search, :index, :new, :create, :auto_complete]
  
  before_filter :initiliase_empty_objects_for_new_pages, :only => [:new, :create]
  before_filter :set_sharing_mode_variables, :only => [:show, :new, :create, :edit, :update]
  
  before_filter :check_is_owner, :only => [:edit, :update, :suggestions, :process_suggestions]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :blob_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :permission_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :bookmark_sweeper, :only => [ :destroy, :favourite, :favourite_delete ]
  cache_sweeper :tag_sweeper, :only => [ :create, :update, :tag, :destroy ]
  cache_sweeper :download_viewing_sweeper, :only => [ :show, :download, :named_download, :named_download_with_version ]
  cache_sweeper :comment_sweeper, :only => [ :comment, :comment_delete ]
  cache_sweeper :rating_sweeper, :only => [ :rate ]
  
  # GET /files;search
  def search
    redirect_to(search_path + "?type=files&query=" + params[:query])
  end
  
  # GET /files/1;download
  def download
    if allow_statistics_logging(@blob)
      @download = Download.create(:contribution => @blob.contribution, :user => (logged_in? ? current_user : nil), :user_agent => request.env['HTTP_USER_AGENT'], :accessed_from_site => accessed_from_website?())
    end
    
    send_data(@version.content_blob.data, :filename => @version.local_name, :type => @version.content_type.mime_type)
    
    #send_file("#{RAILS_ROOT}/#{controller_name}/#{@blob.contributor_type.downcase.pluralize}/#{@blob.contributor_id}/#{@blob.local_name}", :filename => @blob.local_name, :type => @blob.content_type.mime_type)
  end

  # GET /files/:id/download/:name
  def named_download

    # check that we got the right filename for this workflow
    if params[:name] == @blob.local_name
      download
    else
      render :nothing => true, :status => "404 Not Found"
    end
  end

  # GET /files/:id/versions/:version/download/:name
  def named_download_with_version

    # check that we got the right filename for this workflow
    if params[:name] == @version.local_name
      download
    else
      render :nothing => true, :status => "404 Not Found"
    end
  end

  # GET /files
  def index
    respond_to do |format|
      format.html {

        @pivot, problem = calculate_pivot(

            :pivot_options  => Conf.pivot_options,
            :params         => params,
            :user           => current_user,
            :search_models  => [Blob],
            :search_limit   => Conf.max_search_size,

            :locked_filters => { 'CATEGORY' => 'Blob' },

            :active_filters => ["CATEGORY", "TYPE_ID", "TAG_ID", "USER_ID",
                                "LICENSE_ID", "GROUP_ID", "WSDL_ENDPOINT",
                                "CURATION_EVENT", "SERVICE_PROVIDER",
                                "SERVICE_COUNTRY", "SERVICE_STATUS"])

        flash.now[:error] = problem if problem

        @query = params[:query]
        @query_type = 'files'

        # index.rhtml
      }
    end
  end
  
  # GET /files/1
  def show
    if allow_statistics_logging(@blob)
      @viewing = Viewing.create(:contribution => @blob.contribution, :user => (logged_in? ? current_user : nil), :user_agent => request.env['HTTP_USER_AGENT'], :accessed_from_site => accessed_from_website?())
    end
    
    respond_to do |format|
      format.html {

        @lod_nir  = blob_url(@blob)
        @lod_html = blob_url(:id => @blob.id, :format => 'html')
        @lod_rdf  = blob_url(:id => @blob.id, :format => 'rdf')
        @lod_xml  = blob_url(:id => @blob.id, :format => 'xml')

        # show.rhtml
      }

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} files #{@blob.id}`
        }
      end
    end
  end
  
  # GET /files/new
  def new
  end
  
  # GET /files/1;edit
  def edit
  end
  
  # POST /blobs
  def create

    # don't create new blob if no file has been selected
    if params[:blob][:data].nil? || params[:blob][:data].size == 0
      respond_to do |format|
        flash.now[:error] = "Please select a file to upload."
        format.html { render :action => "new" }
      end
    else
      data = params[:blob][:data].read
      params[:blob][:local_name] = params[:blob][:data].original_filename
      content_type = params[:blob][:data].content_type
      params[:blob].delete('data')

      params[:blob][:contributor_type], params[:blob][:contributor_id] = "User", current_user.id

      params[:blob][:license_id] = nil if params[:blob][:license_id] && params[:blob][:license_id] == "0"
   
      @blob = Blob.new(params[:blob])
      @blob.content_blob = ContentBlob.new(:data => data)

      @blob.content_type = ContentType.find_or_create_by_mime_type(:user => current_user, :mime_type => content_type, :category=> 'Blob')

      respond_to do |format|
        if @blob.save
          if params[:blob][:tag_list]
            @blob.tags_user_id = current_user
            @blob.tag_list = convert_tags_to_gem_format params[:blob][:tag_list]
            @blob.update_tags
          end
          # update policy
          @blob.contribution.update_attributes(params[:contribution])
        
          policy_err_msg = update_policy(@blob, params)
          update_layout(@blob, params[:layout])
        
          update_credits(@blob, params)
          update_attributions(@blob, params)
        
          if policy_err_msg.blank?

            @version = @blob.find_version(1)

            format.html {
              if @version.suggestions?
                redirect_to(blob_version_suggestions_path(@blob, @version.version))
              else
                flash[:notice] = 'File was successfully created.'
                  redirect_to blob_url(@blob)
              end
            }

          else
            flash[:notice] = "File was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'blobs', :id => @blob, :action => "edit" }
          end
        else
          format.html { render :action => "new" }
        end
      end
    end
  end
  
  # PUT /files/1
  def update
    # hack for select contributor form
    if params[:contributor_pair]
      params[:contribution][:contributor_type], params[:contribution][:contributor_id] = params[:contributor_pair][:class_id].split("-")
      params.delete("contributor_pair")
    end
    
    # remove protected columns
    if params[:blob]
      [:contributor_id, :contributor_type, :content_type, :content_type_id, :local_name, :created_at, :updated_at].each do |column_name|
        params[:blob].delete(column_name)
      end
    end
    
    params[:blob][:license_id] = nil if params[:blob][:license_id] && params[:blob][:license_id] == "0"

    # Create a new content blob entry if new data is provided.
    if params[:blob][:data] && params[:blob][:data].size > 0
      @blob.build_content_blob(:data => params[:blob][:data].read)
      @blob.local_name = params[:blob][:data].original_filename
      @blob.content_type = ContentType.find_or_create_by_mime_type(:user => current_user, :title => params[:blob][:data].content_type, :mime_type => params[:blob][:data].content_type, :category => 'Blob')
    end

    params[:blob].delete(:data)
    
    respond_to do |format|
      if @blob.update_attributes(params[:blob])
        @blob.refresh_tags(convert_tags_to_gem_format(params[:blob][:tag_list]), current_user) if params[:blob][:tag_list]
        
        policy_err_msg = update_policy(@blob, params)
        update_credits(@blob, params)
        update_attributions(@blob, params)
        update_layout(@blob, params[:layout])
        
        if policy_err_msg.blank?
          format.html {

            if @blob.new_version_number
              @version = @blob.find_version(@blob.new_version_number)
            else
              @version.reload
            end

            if @version.suggestions?
              redirect_to(blob_version_suggestions_path(@blob, @version.version))
            else
              flash[:notice] = 'File was successfully updated.'
              redirect_to blob_url(@blob)
            end
          }
        else
          flash[:error] = policy_err_msg
          format.html { redirect_to :controller => 'blobs', :id => @blob, :action => "edit" }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # DELETE /files/1
  def destroy
    success = @blob.destroy

    respond_to do |format|
      if success
        flash[:notice] = "File has been deleted."
        format.html { redirect_to blobs_url }
      else
        flash[:error] = "Failed to delete File. Please contact your administrator."
        format.html { redirect_to blob_url(@blob) }
      end
    end
  end
  
  # POST /files/1;rate
  def rate
    if @blob.contributor_type == 'User' and @blob.contributor_id == current_user.id
      error("You cannot rate your own file!", "")
    else
      Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @blob.class.to_s, @blob.id, current_user.id])
      
      Rating.create(:rateable => @blob, :user => current_user, :rating => params[:rating])
      
      respond_to do |format|
        format.html { 
          render :update do |page|
            page.replace_html "ratings_inner", :partial => "contributions/ratings_box_inner", :locals => { :contributable => @blob, :controller_name => controller.controller_name }
            page.replace_html "ratings_breakdown", :partial => "contributions/ratings_box_breakdown", :locals => { :contributable => @blob }
          end }
      end
    end
  end
  
  # POST /files/1;tag
  def tag
    @blob.tags_user_id = current_user # acts_as_taggable_redux
    @blob.tag_list = "#{@blob.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @blob.update_tags # hack to get around acts_as_versioned
    @blob.solr_save if Conf.solr_enable
    
    respond_to do |format|
      format.html { 
        render :update do |page|
          unique_tag_count = @blob.tags.uniq.length
          page.replace_html "mini_nav_tag_link", "(#{unique_tag_count})"
          page.replace_html "tags_box_header_tag_count_span", "(#{unique_tag_count})"
          page.replace_html "tags_inner_box", :partial => "tags/tags_box_inner", :locals => { :taggable => @blob, :owner_id => @blob.contributor_id } 
        end
      }
    end
  end
  
  # POST /files/1;favourite
  def favourite
    @blob.bookmarks << Bookmark.create(:user => current_user, :bookmarkable => @blob) unless @blob.bookmarked_by_user?(current_user)
    
    respond_to do |format|
      flash[:notice] = "You have successfully added this item to your favourites."
      format.html { redirect_to blob_url(@blob) }
    end
  end
  
  # DELETE /files/1;favourite_delete
  def favourite_delete
    @blob.bookmarks.each do |b|
      if b.user_id == current_user.id
        b.destroy
      end
    end
    
    respond_to do |format|
      flash[:notice] = "You have successfully removed this item from your favourites."
      redirect_url = params[:return_to] ? params[:return_to] : blob_url(@blob)
      format.html { redirect_to redirect_url }
    end
  end

  def auto_complete
    text = params[:file_name] || ''

    files = Blob.find(:all,
                     :conditions => ["LOWER(title) LIKE ?", text.downcase + '%'],
                     :order => 'title ASC',
                     :limit => 20,
                     :select => 'DISTINCT *')

    files = files.select {|f| Authorization.is_authorized?('view', nil, f, current_user) }

    render :partial => 'contributions/autocomplete_list', :locals => { :contributions => files }
  end
  
  # GET /files/1/versions/1/suggestions
  def suggestions
    @suggestions = @version.suggestions
  end

  # POST /files/1/versions/1/process_suggestions
  def process_suggestions

    @version.revision_comments = params[:revision_comments] if params[:revision_comments]
    @version.body = params[:description] if params[:description]

    success = @version.save

    respond_to do |format|
      format.html {
        if success
          flash[:notice] = 'File was successfully updated.'
          redirect_to blob_version_path(@blob, @version.version)
        else
          render :action => "suggestions"  
        end
      }
    end
  end

  protected
  
  def find_blob_auth
    begin
      blob = Blob.find(params[:id])
      
      if Authorization.is_authorized?(action_name, nil, blob, current_user)
        @blob = blob
        
        if params[:version]
          @version = @blob.find_version(params[:version])
        else
          @version = @blob.versions.last
        end

        @blob_entry_url = url_for :only_path => false,
                            :host => base_host,
                            :id => @blob.id

        @named_download_url = url_for :controller => 'blobs',
                                      :action => 'named_download_with_version',
                                      :id => @blob.id, 
                                      :version => @version.version, 
                                      :name => @version.local_name

      else
        if logged_in? 
          error("File not found (id not authorized)", "is invalid (not authorized)")
        else
          find_blob_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("File not found", "is invalid")
    end
  end
  
  def initiliase_empty_objects_for_new_pages
    if ["new", "create"].include?(action_name)
      @blob = Blob.new
    end
  end
  
  def set_sharing_mode_variables
    if @blob
      case action_name
        when "new"
          @sharing_mode  = 0
          @updating_mode = 6
        when "create", "update"
          @sharing_mode  = params[:sharing][:class_id].to_i if params[:sharing]
          @updating_mode = params[:updating][:class_id].to_i if params[:updating]
        when "show", "edit"
          @sharing_mode  = @blob.contribution.policy.share_mode
          @updating_mode = @blob.contribution.policy.update_mode
      end
    end
  end
  
  def check_is_owner
    if @blob
      error("You are not authorised to manage this File", "") unless @blob.owner?(current_user)
    end
  end
  
  private
  
  def error(notice, message, attr=:id)
    flash[:error] = notice
     (err = Blob.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to blobs_url }
    end
  end
end
