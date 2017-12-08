# myExperiment: app/controllers/blobs_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlobsController < ApplicationController

  include ApplicationHelper
  include TaggingUtils

  before_filter :login_required, :except => [:index, :show, :download, :named_download, :named_download_with_version, :statistics, :search, :auto_complete]

  before_filter :find_blob_auth, :except => [:search, :index, :new, :create, :auto_complete]
  
  before_filter :initiliase_empty_objects_for_new_pages, :only => [:new, :create]
  before_filter :set_sharing_mode_variables, :only => [:show, :new, :create, :edit, :update]
  
  before_filter :check_is_owner, :only => [:edit, :update, :suggestions, :process_suggestions]

  before_filter :check_context, :only => :index
  
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
    
    send_data(@version.content_blob.data, :filename => @version.local_name, :type => @version.content_type.mime_type, :disposition => (params[:disposition] || 'attachment'))
    
    #send_file("#{Rails.root}/#{controller_name}/#{@blob.contributor_type.downcase.pluralize}/#{@blob.contributor_id}/#{@blob.local_name}", :filename => @blob.local_name, :type => @blob.content_type.mime_type)
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

        @query = params[:query]
        @query_type = 'files'
        pivot_options = Conf.pivot_options.dup
        unless @query.blank?
          pivot_options["order"] = [{"order" => "id ASC", "option" => "relevance", "label" => "Relevance"}] + pivot_options["order"]
        end

        locked_filters = { 'CATEGORY' => 'Blob' }

        if @context
          context_filter = visible_name(@context).upcase + "_ID"
          locked_filters[context_filter] = @context.id.to_s
        end

        @pivot, problem = calculate_pivot(

            :pivot_options  => Conf.pivot_options,
            :params         => params,
            :user           => current_user,
            :search_models  => [Blob],
            :search_limit   => Conf.max_search_size,

            :locked_filters => locked_filters,

            :active_filters => ["CATEGORY", "TYPE_ID", "TAG_ID", "USER_ID",
                                "LICENSE_ID", "GROUP_ID", "WSDL_ENDPOINT",
                                "CURATION_EVENT"])

        flash.now[:error] = problem if problem

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
      d = params[:blob].delete('data')

      params[:blob][:contributor_type], params[:blob][:contributor_id] = "User", current_user.id

      params[:blob][:license_id] = nil if params[:blob][:license_id] && params[:blob][:license_id] == "0"
   
      @blob = Blob.new(params[:blob])
      @blob.content_blob = ContentBlob.new(:data => data)
      @blob.content_type = get_content_type(d)

      respond_to do |format|
        if @blob.save
          Activity.create(:subject => current_user, :action => 'create', :objekt => @blob, :auth => @blob)
          if params[:tag_list]
            replace_tags(@blob, current_user, convert_tags_to_gem_format(params[:tag_list]))
          end
          # update policy
          @blob.contribution.update_attributes(params[:contribution])
        
          policy_err_msg = update_policy(@blob, params, current_user)

          update_credits(@blob, params)
          update_attributions(@blob, params)
        
          if policy_err_msg.blank?
            update_layout(@blob, params[:layout]) unless params[:policy_type] == "group"
            @version = @blob.find_version(1)

            format.html {
              if @version.suggestions?
                redirect_to(blob_version_suggestions_path(@blob, @version.version))
              else
                flash[:notice] = 'File was successfully created.'
                  redirect_to blob_path(@blob)
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
      @blob.content_type = get_content_type(params[:blob][:data])
    end

    params[:blob].delete(:data)
    
    respond_to do |format|
      if @blob.update_attributes(params[:blob])

        if @blob.new_version_number
          Activity.create(:subject => current_user, :action => 'create', :objekt => @blob.find_version(@blob.new_version_number), :extra => @blob.new_version_number, :auth => @blob)
        else
          Activity.create(:subject => current_user, :action => 'edit', :objekt => @blob, :auth => @blob)
        end

        replace_tags(@blob, current_user, convert_tags_to_gem_format(params[:tag_list])) if params[:tag_list]
        
        policy_err_msg = update_policy(@blob, params, current_user)
        update_credits(@blob, params)
        update_attributions(@blob, params)

        if policy_err_msg.blank?
          update_layout(@blob, params[:layout]) unless params[:policy_type] == "group"

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
              redirect_to blob_path(@blob)
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
        format.html { redirect_to blobs_path }
      else
        flash[:error] = "Failed to delete File. Please contact your administrator."
        format.html { redirect_to blob_path(@blob) }
      end
    end
  end
  
  # POST /files/1;rate
  def rate
    unless @blob.contributor_type == 'User' and @blob.contributor_id == current_user.id
      Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @blob.class.to_s, @blob.id, current_user.id])

      rating = Rating.create(:rateable => @blob, :user => current_user, :rating => params[:rating])
      Activity.create(:subject => current_user, :action => 'create', :objekt => rating, :auth => @blob, :extra => params[:rating].to_i)
      
      respond_to do |format|
        format.html do
          render :update do |page|
            page.replace_html "ratings_inner", :partial => "contributions/ratings_box_inner", :locals => { :contributable => @blob, :controller_name => controller.controller_name }
            page.replace_html "ratings_breakdown", :partial => "contributions/ratings_box_breakdown", :locals => { :contributable => @blob }
          end
        end
      end
    end
  end
  
  # POST /files/1;tag
  def tag
    current_user.tag(@blob, :with => convert_tags_to_gem_format(params[:tag_list]), :on => :tags)

    respond_to do |format|
      format.html {
        render :partial => "tags/tags_box_inner", :locals => { :taggable => @blob, :owner_id => @blob.contributor_id }
      }
    end
  end
  
  # POST /files/1;favourite
  def favourite

    bookmark = Bookmark.new(:user => current_user, :bookmarkable => @blob)

    success = bookmark.save unless @blob.bookmarked_by_user?(current_user)

    if success
      Activity.create(:subject => current_user, :action => 'create', :objekt => bookmark, :auth => @blob)
    end
    
    respond_to do |format|
      flash[:notice] = "You have successfully added this item to your favourites."
      format.html { redirect_to blob_path(@blob) }
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
      redirect_url = params[:return_to] ? params[:return_to] : blob_path(@blob)
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

    files = files.select {|f| Authorization.check('view', f, current_user) }

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

    action_permissions = {
      "create"                      => "create",
      "destroy"                     => "destroy",
      "download"                    => "download",
      "edit"                        => "edit",
      "favourite"                   => "view",
      "favourite_delete"            => "view",
      "index"                       => "view",
      "named_download"              => "download",
      "named_download_with_version" => "download",
      "new"                         => "create",
      "process_suggestions"         => "edit",
      "rate"                        => "view",
      "search"                      => "view",
      "show"                        => "view",
      "statistics"                  => "view",
      "suggestions"                 => "view",
      "tag"                         => "view",
      "update"                      => "edit"
    }

    begin
      blob = Blob.find(params[:id])
      
      if Authorization.check(action_permissions[action_name], blob, current_user)
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
          render_401("You are not authorized to access this file.")
        else
          find_blob_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      render_404("File not found.")
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
      render_401("You are not authorised to manage this file.") unless @blob.owner?(current_user)
    end
  end

  private

  def get_content_type(data)
    content_type = data.content_type

    # Hack to recognize component profiles
    if @blob.content_blob.data[0..512].include?('http://ns.taverna.org.uk/2012/component/profile')
      content_type = 'application/vnd.taverna.component-profile+xml'
    end

    ContentType.find_or_create_by_mime_type(:user => current_user,
                                            :title => content_type,
                                            :mime_type => content_type,
                                            :category=> 'Blob')

  end
end
