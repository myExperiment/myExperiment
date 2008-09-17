# myExperiment: app/controllers/workflows_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class WorkflowsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :download, :named_download, :launch, :search, :all]
  
  before_filter :find_workflows, :only => [:all]
  before_filter :find_workflows_rss, :only => [:index]
  before_filter :find_workflow_auth, :except => [:search, :index, :new, :create, :all]
  
  before_filter :initiliase_empty_objects_for_new_pages, :only => [:new, :create, :new_version, :create_version]
  
  before_filter :check_file_size, :only => [:create, :create_version]
  before_filter :check_custom_workflow_type => [:create, :create_version]
  
  before_filter :check_is_owner, :only => [:edit, :update]
  
  before_filter :invalidate_listing_cache, :only => [:show, :download, :named_download, :launch, :update, :update_version, :comment, :comment_delete, :rate, :tag, :destroy, :destroy_version]
  before_filter :invalidate_tags_cache, :only => [:create, :update, :delete, :tag]
  
  # GET /workflows;search
  def search

    @query = params[:query]
    
    @workflows = SOLR_ENABLE ? Workflow.find_by_solr(@query, :limit => 100).results : []
    
    respond_to do |format|
      format.html # search.rhtml
    end
  end
  
  # POST /workflows/1;favourite
  def favourite
    @workflow.bookmarks << Bookmark.create(:user => current_user) unless @workflow.bookmarked_by_user?(current_user)
    
    respond_to do |format|
      flash[:notice] = "You have successfully added this item to your favourites."
      format.html { redirect_to workflow_url(@workflow) }
    end
  end
  
  # DELETE /workflows/1;favourite_delete
  def favourite_delete
    @workflow.bookmarks.each do |b|
      if b.user_id == current_user.id
        b.destroy
      end
    end
    
    respond_to do |format|
      flash[:notice] = "You have successfully removed this item from your favourites."
      redirect_url = params[:return_to] ? params[:return_to] : workflow_url(@workflow)
      format.html { redirect_to redirect_url }
    end
  end
  
  # POST /workflows/1;comment
  def comment
    text = params[:comment][:comment]
    
    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @workflow.comments << comment
    end
  
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @workflow } }
    end
  end
  
  # DELETE /workflows/1;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type.downcase == 'workflow' and comment.commentable_id == @workflow.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @workflow } }
    end
  end
  
  def comments_timeline
    respond_to do |format|
      format.html # comments_timeline.rhtml
    end
  end
  
  # For simile timeline
  def comments
    @comments = Comment.find(:all, :conditions => [ "commentable_id = ? AND commentable_type = ? AND created_at > ? AND created_at < ?", @workflow.id, 'Workflow', params[:start].to_time, params[:end].to_time ] )
    respond_to do |format|
      format.json { render :partial => 'comments/timeline_json', :layout => false }
    end
  end
  
  # POST /workflows/1;rate
  def rate
    if @workflow.contributor_type == 'User' and @workflow.contributor_id == current_user.id
      error("You cannot rate your own workflow!", "")
    else
      Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @workflow.class.to_s, @workflow.id, current_user.id])
      
      @workflow.ratings << Rating.create(:user => current_user, :rating => params[:rating])
      
      respond_to do |format|
        format.html { 
          render :update do |page|
            page.replace_html "ratings_inner", :partial => "contributions/ratings_box_inner", :locals => { :contributable => @workflow, :controller_name => controller.controller_name }
            page.replace_html "ratings_breakdown", :partial => "contributions/ratings_box_breakdown", :locals => { :contributable => @workflow }
          end }
      end
    end
  end
  
  # POST /workflows/1;tag
  def tag

    Tag.parse(convert_tags_to_gem_format(params[:tag_list])).each do |name|
      @workflow.add_tag(name, current_user)
    end

    @workflow.tag_list = "#{@workflow.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @workflow.tags_user_id = current_user # acts_as_taggable_redux
    @workflow.tag_list = "#{@workflow.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @workflow.update_tags # hack to get around acts_as_versioned

    respond_to do |format|
      format.html { render :partial => "tags/tags_box_inner", :locals => { :taggable => @workflow, :owner_id => @workflow.contributor_id } }
    end
  end
  
  # GET /workflows/1;download
  def download
    @download = Download.create(:contribution => @workflow.contribution, :user => (logged_in? ? current_user : nil))
    
    send_data(@viewing_version.content_blob.data, :filename => @workflow.filename(@viewing_version_number), :type => @workflow.content_type)
  end
  
  # GET /workflows/:id/download/:name
  def named_download

    # check that we got the right filename for this workflow
    if params[:name] == @workflow.filename
      download
    else
      render :nothing => true, :status => "404 Not Found"
    end
  end

  # GET /workflows/:id/launch.whip
  def launch
    
    wwf = Whip::WhipWorkflow.new()

    wwf.title       = @viewing_version.title
    wwf.datatype    = Whip::Taverna1DataType
    wwf.author      = @workflow.contributor_name
    wwf.name        = @workflow.filename(@viewing_version_number)
    wwf.summary     = @viewing_version.body
    wwf.version     = @viewing_version.version.to_s
    wwf.workflow_id = @workflow.id.to_s
    wwf.updated     = @viewing_version.updated_at
    wwf.data        = @viewing_version.scufl

    dir = 'tmp/bundles'

    FileUtils.mkdir(dir) if not File.exists?(dir)
    file_path = Whip::filePath(wwf, dir)

    Whip::bundle(wwf, dir)

    respond_to do |format|
      format.whip { 
        send_data(File.read(file_path), :filename => "#{@viewing_version.unique_name}_#{@viewing_version.version}.whip",
            :type => "application/whip-archive")
      }
    end
  end

  # GET /workflows
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.rss do
        #@workflows = Workflow.find(:all, :order => "updated_at DESC") # list all (if required)
        render :action => 'index.rxml', :layout => false
      end
    end
  end
  
  # GET /workflows/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end

  # GET /workflows/1
  def show
    @viewing = Viewing.create(:contribution => @workflow.contribution, :user => (logged_in? ? current_user : nil))

    @sharing_mode  = determine_sharing_mode(@workflow)
    @updating_mode = determine_updating_mode(@workflow)
    
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /workflows/new
  def new
    @workflow = Workflow.new
    
    @sharing_mode  = 0
    @updating_mode = 6
  end

  # GET /workflows/1/new_version
  def new_version
  end

  # GET /workflows/1/edit
  def edit
    @sharing_mode  = determine_sharing_mode(@workflow)
    @updating_mode = determine_updating_mode(@workflow)
  end
  
  # GET /workflows/1/edit_version
  def edit_version
  end

  # POST /workflows
  def create
    file = params[:workflow][:file]
    
    @workflow = Workflow.new
    @workflow.contributor = current_user
    @workflow.license = params[:workflow][:license]
    @workflow.content_blob = ContentBlob.new(:data => file.read)
    @workflow.file_ext = file.original_filename.split(".").last.downcase
    
    file.rewind
    
    # Check whether user has selected to infer metadata or provided custom metadata...
    
    # Infer metadata.
    if params[:metadata_choice] == 'infer'
      # Check that the file uploaded is recognised and can be parsed...
      
      worked = infer_metadata(@workflow, file)
      
      if worked
        respond_to do |format|
          flash[:error] = "We were unable to infer metadata from the workflow file/script selected. Please enter custom metadata for this workflow."
          params[:metadata_choice] = 'custom'
          format.html { render :action => "new" }
        end
        return
      end
      
    # Custom metadata provided.
    elsif params[:metadata_choice] == 'custom'
      set_custom_metadata(@workflow)
    end
    
    respond_to do |format|
      if @workflow.save
        if params[:workflow][:tag_list]
          @workflow.refresh_tags(convert_tags_to_gem_format(params[:workflow][:tag_list]), current_user)
        end
        
        update_policy(@workflow, params)
    
        # Credits and Attributions:
        update_credits(@workflow, params)
        update_attributions(@workflow, params)
        
        # Refresh the types handler list of types if a new type was supplied this time.
        WorkflowTypesHandler.refresh_all_known_types! if params[:workflow][:type] == 'other'

        flash[:notice] = 'Workflow was successfully created.'
        format.html { redirect_to workflow_url(@workflow) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  # POST /workflows/1;create_version
  def create_version
    file = params[:workflow][:file]
    
    # Because this is a new version of an existing workflow
    # we use the existing workflow object to set the data,
    # but then save it as a new version.
    
    original_type_display_name = @workflow.type_display_name
    original_file_ext = @workflow.file_ext
    
    @workflow.contributor = current_user
    @workflow.content_blob = ContentBlob.new(:data => file.read)
    @workflow.file_ext = file.original_filename.split(".").last.downcase
    
    file.rewind
    
    # Check whether user has selected to infer metadata or provided custom metadata...
    
    # Infer metadata.
    if params[:metadata_choice] == 'infer'
      # Check that the file uploaded is recognised and can be parsed...
      
      worked = infer_metadata(@workflow, file)
      
      unless worked
        respond_to do |format|
          flash[:error] = "We were unable to infer metadata from the workflow file/script selected. Please enter custom metadata for this workflow."
          params[:metadata_choice] = 'custom'
          format.html { render :action => :new_version }
        end
        return
      end
      
    # Custom metadata provided.
    elsif params[:metadata_choice] == 'custom'
      set_custom_metadata(@workflow)
    end
    
    # Check workflow type and file extension of new workflow is same as original
    if (original_type_display_name != @workflow.type_display_name) || (original_file_ext != @workflow.file_ext)
      respond_to do |format|
        flash[:error] = "The workflow you have provided is not of the same content type as the original. Please upload a workflow of type '#{original_content_type}'"
        format.html { render :action => :new_version }
      end
      return
    end
    
    respond_to do |format|
      if @workflow.valid? && @workflow.save_as_new_version(params[:new_workflow][:comments])
        flash[:notice] = 'New workflow version successfully created.'
        format.html { redirect_to workflow_url(@workflow) }
      else
        flash[:error] = 'Failed to upload and save new version. Check that you have provided the required data.'       
        format.html { render :action => :new_version }
      end
    end
          
  end

  # PUT /workflows/1
  def update
    # remove protected columns
    if params[:workflow]
      [:contribution, :contributor_id, :contributor_type, :image, :svg, :created_at, :updated_at, :current_version, :content_type, :file_ext, :content_blob_id].each do |column_name|
        params[:workflow].delete(column_name)
      end
    end
    
    # remove owner only columns
    unless @workflow.contribution.owner?(current_user)
      if params[:workflow]
        [:unique_name, :license].each do |column_name|
          params[:workflow].delete(column_name)
        end
      end
    end
    
    respond_to do |format|
      if @workflow.update_attributes(params[:workflow])

        if params[:workflow][:tag_list]
          @workflow.refresh_tags(convert_tags_to_gem_format(params[:workflow][:tag_list]), current_user)
        end

        update_policy(@workflow, params)
        update_credits(@workflow, params)
        update_attributions(@workflow, params)

        flash[:notice] = 'Workflow was successfully updated.'
        format.html { redirect_to workflow_url(@workflow) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # PUT /workflows/1;update_version
  def update_version
    workflow_title = @workflow.title
    
    if params[:version]
      # Update differently based on whether a new preview image has been specified or not:
      # (But only set image if platform is not windows).
      if params[:workflow][:preview].size == 0
        success = @workflow.update_version(params[:version], :title => params[:workflow][:title], :body => params[:workflow][:body]) 
      else
        if RUBY_PLATFORM =~ /mswin32/
          success = false
        else
          success = @workflow.update_version(params[:version], 
                                             :title => params[:workflow][:title], 
                                             :body => params[:workflow][:body], 
                                             :image => params[:workflow][:preview])
        end
      end
    else
      success = false
    end
    
    respond_to do |format|
      if success
        flash[:notice] = "Workflow version #{params[:version]}: \"#{workflow_title}\" has been updated."
        format.html { redirect_to(workflow_url(@workflow) + "?version=#{params[:version]}") }
      else
        flash[:error] = "Failed to update Workflow version."
        if params[:version]
          format.html { render :action => :edit_version }
        else
          format.html { redirect_to workflow_url(@workflow) }
        end
      end
    end
  end
  
  # DELETE /workflows/1
  def destroy
    workflow_title = @workflow.title

    success = @workflow.destroy

    respond_to do |format|
      if success
        flash[:notice] = "Workflow \"#{workflow_title}\" has been deleted"
        format.html { redirect_to workflows_url }
      else
        flash[:error] = "Failed to delete Workflow entry \"#{workflow_title}\""
        format.html { redirect_to workflow_url(@workflow) }
      end
    end
  end
  
  # DELETE /workflows/1;destroy_version?version=1
  def destroy_version
    workflow_title = @viewing_version.title
    
    if params[:version]
      if @workflow.find_version(params[:version]) == false
        error("Version not found (is invalid)", "not found (is invalid)", :version)
      end
      if @workflow.versions.length < 2
        error("Can't delete all versions", " is not allowed", :version)
      end
      success = @workflow.destroy_version(params[:version].to_i)
    else
      success = false
    end
  
    respond_to do |format|
      if success
        flash[:notice] = "Workflow version #{params[:version]}: \"#{workflow_title}\" has been deleted"
        format.html { redirect_to workflow_url(@workflow) }
      else
        flash[:error] = "Failed to delete Workflow version. Please report this."
        if params[:version]
          format.html { redirect_to(workflow_url(@workflow) + "?version=#{params[:version]}") }
        else
          format.html { redirect_to workflow_url(@workflow) }
        end
      end
    end
  end
  
protected

  def find_workflows
    found = Workflow.find(:all, 
                          construct_options.merge({:page => { :size => 20, :current => params[:page] },
                          :include => [ { :contribution => :policy }, :tags, :ratings ],
                          :order => "workflows.updated_at DESC" }))
    
    found.each do |workflow|
      workflow.content_blob.data = nil unless workflow.authorized?("download", (logged_in? ? current_user : nil))
    end
    
    @workflows = found
  end
  
  def find_workflows_rss
    # Only carry out if request is for RSS
    if params[:format] and params[:format].downcase == 'rss'
      found = Workflow.find(:all, :order => "workflows.updated_at DESC", :limit => 30, :include => [ { :contribution => :policy } ])
      
      @rss_workflows = [ ]
      
      found.each do |workflow|
        @rss_workflows << workflow if workflow.authorized?("show", (logged_in? ? current_user : nil))
      end
    end
  end
  
  def find_workflow_auth
    begin
      # attempt to authenticate the user before you return the workflow
      login_required if login_available?
    
      # Use eager loading only for 'show' action
      if action_name == 'show'
        workflow = Workflow.find(params[:id], :include => [ { :contribution => :policy }, :citations, :tags, :ratings, :versions, :reviews, :comments ])
      else
        workflow = Workflow.find(params[:id])
      end
      
      permission = action_name
      permission = 'show' if action_name == 'launch'

      if workflow.authorized?(permission, (logged_in? ? current_user : nil))
        @latest_version_number = workflow.current_version
        @workflow = workflow
        if params[:version]
          if (viewing = @workflow.find_version(params[:version]))
            @viewing_version_number = params[:version].to_i
            @viewing_version = viewing
          else
            error("Workflow version not found (possibly has been deleted)", "not found (is invalid)", :version)
          end
        else
          @viewing_version_number = @latest_version_number
          @viewing_version = @workflow.find_version(@latest_version_number)
        end
        
        @authorised_to_download = @workflow.authorized?("download", (logged_in? ? current_user : nil))
        @authorised_to_edit = logged_in? && @workflow.authorized?("edit", (logged_in? ? current_user : nil))
        
        # remove scufl from workflow if the user is not authorized for download
        @viewing_version.content_blob.data = nil unless @authorised_to_download
        @workflow.content_blob.data = nil unless @authorised_to_download
          
        @workflow_entry_url = url_for :only_path => false,
                                :host => base_host,
                                :id => @workflow.id
        
        @download_url = url_for :action => 'download',
                                :id => @workflow.id, 
                                :version => @viewing_version_number.to_s
        
        @named_download_url = url_for @workflow.named_download_url + "?version=#{@viewing_version_number.to_s}" 
                                      
        @launch_url = "/workflows/#{@workflow.id}/launch.whip?version=#{@viewing_version_number.to_s}"

        puts "@latest_version_number = #{@latest_version_number}"
        puts "@viewing_version_number = #{@viewing_version_number}"
        puts "@workflow.image != nil = #{@workflow.image != nil}"
      else
        if logged_in?
          error("Workflow not found (id not authorized)", "is invalid (not authorized)")
          return false
        else
          find_workflow_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Workflow not found", "is invalid")
      return false
    end
  end
  
  def initiliase_empty_objects_for_new_pages
    # HACK: required for the FCKEditor description box, which is used in both new and new_version actions.
    @new_workflow = Workflow.new
  end
  
  def check_file_size
    case action_name
      when "create"           then view_to_render_on_fail = "new"
      when "create_version"   then view_to_render_on_fail = "new_version"
    end
    
    # Check that a file has been selected 
    if params[:workflow][:file].size == 0
      respond_to do |format|
        flash[:error] = "Please select a valid workflow file to upload. If you have selected a file, it might be empty."
        format.html { render :action => view_to_render_on_fail }
      end
      return false
    # Check that the size of the workflow file doesn't exceed the max size
    elsif params[:workflow][:file].size > WORKFLOW_UPLOAD_MAX_BYTES
      respond_to do |format|
        flash[:error] = "The workflow file/script uploaded is too big. The maximum upload size for workflows is #{number_to_human_size(WORKFLOW_UPLOAD_MAX_BYTES)}."
        format.html { render :action => view_to_render_on_fail }
      end
      return false
    end
  end
  
  def check_custom_workflow_type
    case action_name
      when "create"           then view_to_render_on_fail = "new"
      when "create_version"   then view_to_render_on_fail = "new_version"
    end
    
    # If a custom workflow type has been specified, check that it is not "Other" or "other" as this can cause havoc in the UI.
    if params[:metadata_choice] == 'custom' && params[:workflow][:type].downcase == 'other' && params[:workflow][:type_other].downcase == 'other'
      respond_to do |format|
        flash[:error] = "Naughty naughty! You cannot specify a new workflow type of \"#{custom_type_specified}\""
        format.html { render :action => view_to_render_on_fail }
      end
      return false
    end
  end
  
  def check_is_owner
    if @workflow
      error("You are not authorised to manage this Workflow", "") unless @workflow.owner?(current_user)
    end
  end
  
  def invalidate_listing_cache
    if @workflow
      expire_fragment(:controller => 'workflows_cache', :action => 'listing', :id => @workflow.id)
    end
  end
  
  def invalidate_tags_cache
    expire_fragment(:controller => 'workflows', :action => 'all_tags')
    expire_fragment(:controller => 'sidebar_cache', :action => 'tags', :part => 'most_popular_tags')
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Workflow.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to workflows_url }
    end
  end
  
  def construct_options
    valid_keys = ["contributor_id", "contributor_type"]
    
    cond_sql = ""
    cond_params = []
    
    params.each do |key, value|
      next if value.nil?
      
      if valid_keys.include? key
        cond_sql << " AND " unless cond_sql.empty?
        cond_sql << "#{key} = ?" 
        cond_params << value
      end
    end
    
    options = {:order => "updated_at DESC"}
    
    # added to faciliate faster requests for iGoogle gadgets
    # ?limit=0 returns all workflows (i.e. no limit!)
    options = options.merge({:limit => params[:limit]}) if params[:limit] and (params[:limit].to_i != 0)
    
    options = options.merge({:conditions => [cond_sql] + cond_params}) unless cond_sql.empty?
    
    options
  end
  
  # Method used in the create and create_version methods.
  def infer_metadata(workflow_to_set, file)
    # Try and get a processor that can be used to process this type of workflow
    processor_class = WorkflowTypesHandler.processor_class_for_file(file)
    
    # Rewind the file, just in case
    file.rewind
    
    # Status check variable
    worked = true
    
    if processor_class.nil?
      worked = false
    else
      # Check that the processor can do inferring of metadata
      if processor_class.can_infer_metadata?
        begin
          processor_instance = processor_class.new(file.read)
          
          workflow_to_set.title = processor_instance.get_title
          workflow_to_set.body = processor_instance.get_description
          
          workflow_to_set.content_type = processor_class.content_type
          
          # Set the internal unique name for this workflow entry.
          # For the create_version action this will not do anything 
          # as the set_unique_name method should only set the unique name once.
          workflow_to_set.set_unique_name
          
          workflow_to_set.image, workflow_to_set.svg = processor_instance.get_preview_images if processor_class.can_generate_preview?
        rescue Exception => ex
          worked = false
          logger.error("ERROR: some processing failed in workflow processor '#{processor_class.to_s}'.")
          logger.error("EXCEPTION: " + ex)
        end
      else
        # We cannot infer metadata
        worked = false
      end
    end
    
    return worked
  end
  
  # Method used in the create and create_version methods.
  def set_custom_metadata(workflow_to_set)
    workflow_to_set.title = params[:workflow][:title]
    workflow_to_set.body = params[:new_workflow][:body]
    
    # Only set content_type if not already set in the workflow object
    if workflow_to_set.content_type.blank?
      # Workflow content type is either one supported by a workflow processor, or a previously set type in the db, or a custom one.
    
      wf_type = params[:workflow][:type]
    
      if wf_type.downcase == 'other'
        wf_type = params[:workflow][:type_other]
      else
        wf_type = WorkflowTypesHandler.content_type_for_type_display_name(wf_type)
      end
      
      workflow_to_set.content_type = wf_type
    end
    
    # Preview image
    # TODO: kept getting permission denied errors from the file_column and rmagick code, so disable for windows, for now.
    unless RUBY_PLATFORM =~ /mswin32/
      workflow_to_set.image = params[:workflow][:preview]
    end
    
    # Set the internal unique name for this workflow entry.
    # For the create_version action this will not do anything 
    # as the set_unique_name method should only set the unique name once. 
    workflow_to_set.set_unique_name
  end

end

