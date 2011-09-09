# myExperiment: app/controllers/blobs_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlobsController < ApplicationController

  include ApplicationHelper

  before_filter :login_required, :except => [:index, :show, :download, :named_download, :statistics, :search]
  
  before_filter :find_blob_auth, :except => [:search, :index, :new, :create]
  
  before_filter :initiliase_empty_objects_for_new_pages, :only => [:new, :create]
  before_filter :set_sharing_mode_variables, :only => [:show, :new, :create, :edit, :update]
  
  before_filter :check_is_owner, :only => [:edit, :update]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :blob_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :permission_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :bookmark_sweeper, :only => [ :destroy, :favourite, :favourite_delete ]
  cache_sweeper :tag_sweeper, :only => [ :create, :update, :tag, :destroy ]
  cache_sweeper :download_viewing_sweeper, :only => [ :show, :download, :named_download ]
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
    
    send_data(@blob.content_blob.data, :filename => @blob.local_name, :type => @blob.content_type.mime_type)
    
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

  # GET /files
  def index
    respond_to do |format|
      format.html {
        @pivot_options = pivot_options

        begin
          expr = parse_filter_expression(params["filter"]) if params["filter"]
        rescue Exception => ex
          puts "ex = #{ex.inspect}"
          flash.now[:error] = "Problem with query expression: #{ex}"
          expr = nil
        end

        @pivot = contributions_list(Contribution, params, current_user,
            :lock_filter => { 'CATEGORY' => 'Blob' },
            :filters     => expr)

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

        @lod_nir  = file_url(@blob)
        @lod_html = formatted_file_url(:id => @blob.id, :format => 'html')
        @lod_rdf  = formatted_file_url(:id => @blob.id, :format => 'rdf')
        @lod_xml  = formatted_file_url(:id => @blob.id, :format => 'xml')

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
    if params[:blob][:data].size == 0
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

      @blob.content_type = ContentType.find_by_mime_type(content_type)

      if @blob.content_type.nil?
        @blob.content_type = ContentType.create(:user_id => current_user.id, :mime_type => content_type, :title => content_type)
      end

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
        
          update_credits(@blob, params)
          update_attributions(@blob, params)
        
          if policy_err_msg.blank?
            flash[:notice] = 'File was successfully created.'
            format.html { redirect_to file_url(@blob) }
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

    # 'Data' (ie: the actual file) cannot be updated!
    params[:blob].delete('data') if params[:blob][:data]
    
    respond_to do |format|
      if @blob.update_attributes(params[:blob])
        @blob.refresh_tags(convert_tags_to_gem_format(params[:blob][:tag_list]), current_user) if params[:blob][:tag_list]
        
        policy_err_msg = update_policy(@blob, params)
        update_credits(@blob, params)
        update_attributions(@blob, params)
        
        if policy_err_msg.blank?
          flash[:notice] = 'File was successfully updated.'
          format.html { redirect_to file_url(@blob) }
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
        format.html { redirect_to files_url }
      else
        flash[:error] = "Failed to delete File. Please contact your administrator."
        format.html { redirect_to file_url(@blob) }
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
    @blob.bookmarks << Bookmark.create(:user => current_user) unless @blob.bookmarked_by_user?(current_user)
    
    respond_to do |format|
      flash[:notice] = "You have successfully added this item to your favourites."
      format.html { redirect_to file_url(@blob) }
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
      redirect_url = params[:return_to] ? params[:return_to] : file_url(@blob)
      format.html { redirect_to redirect_url }
    end
  end
  
  protected
  
  def find_blob_auth
    begin
      blob = Blob.find(params[:id])
      
      if Authorization.is_authorized?(action_name, nil, blob, current_user)
        @blob = blob
        
        @blob_entry_url = url_for :only_path => false,
                            :host => base_host,
                            :id => @blob.id

        @named_download_url = url_for :controller => 'files',
                                      :action => 'named_download',
                                      :id => @blob.id, 
                                      :name => @blob.local_name

      else
        if logged_in? 
          error("File not found (id not authorized)", "is invalid (not authorized)")
          return false
        else
          find_blob_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("File not found", "is invalid")
      return false
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
      format.html { redirect_to files_url }
    end
  end
end
