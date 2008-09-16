# myExperiment: app/controllers/workflows_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class WorkflowsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :download, :named_download, :launch, :search, :all]
  
  before_filter :find_workflows, :only => [:all]
  before_filter :find_workflows_rss, :only => [:index]
  before_filter :find_workflow_auth, :except => [:search, :index, :new, :create, :all]
  
  before_filter :check_is_owner, :only => [:edit, :update]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :workflow_sweeper, :only => [ :create, :create_version, :launch, :update, :update_version, :destroy_version, :destroy ]
  cache_sweeper :download_viewing_sweeper, :only => [ :show, :download, :named_download, :launch ]
  cache_sweeper :permission_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :bookmark_sweeper, :only => [ :destroy, :favourite, :favourite_delete ]
  cache_sweeper :tag_sweeper, :only => [ :create, :update, :tag, :destroy ]
  cache_sweeper :comment_sweeper, :only => [ :comment, :comment_delete ]
  cache_sweeper :rating_sweeper, :only => [ :rate ]
  
  # These are provided by the Taverna gem
  require 'scufl/model'
  require 'scufl/parser'
  require 'scufl/dot'
  
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
    
    send_data(@viewing_version.content_blob.data, :filename => @viewing_version.unique_name + ".xml", :type => "application/vnd.taverna.scufl+xml")
  end
  
  # GET /workflows/:id/download/:name
  def named_download

    # check that we got the right filename for this workflow
    if params[:name] == "#{@viewing_version.unique_name}.xml"
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
    wwf.name        = "#{@viewing_version.unique_name}_#{@viewing_version.version}.xml"
    wwf.summary     = @viewing_version.body
    wwf.version     = @viewing_version.version.to_s
    wwf.workflow_id = @workflow.id.to_s
    wwf.updated     = @viewing_version.updated_at
    wwf.data        = @viewing_version.content_blob.data

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

  # GET /workflows/1;new_version
  def new_version
  end

  # GET /workflows/1;edit
  def edit
    @sharing_mode  = determine_sharing_mode(@workflow)
    @updating_mode = determine_updating_mode(@workflow)
  end
  
  # GET /workflows/1;edit_version
  def edit_version
  end

  # POST /workflows
  def create

    # don't create new workflow if no file has been selected
    if params[:workflow][:scufl].size == 0
      flash[:error] = "Please select a workflow file to upload."
      redirect_to :action => :new
    else
      params[:workflow][:contributor_type], params[:workflow][:contributor_id] = "User", current_user.id

      scufl_first_k = params[:workflow][:scufl].read(1024)
      params[:workflow][:scufl].rewind

      # if first Kb of uploaded scufl contains a '<scufl>' tag then it is probably an XML workflow and can be processed
      if scufl_first_k !~ %r{<[^<>]*scufl[^<>]*>}
        flash[:error] = "File must be a Taverna workflow. Please select a workflow file."
        redirect_to :action => :new
      else
        # create workflow using helper methods
        @workflow = create_workflow(params[:workflow])
    
        respond_to do |format|
          if @workflow.save
            if params[:workflow][:tag_list]
              @workflow.refresh_tags(convert_tags_to_gem_format(params[:workflow][:tag_list]), current_user)
            end
                
            @workflow.contribution.update_attributes(params[:contribution])

            policy_err_msg = update_policy(@workflow, params)
        
            # Credits and Attributions:
            update_credits(@workflow, params)
            update_attributions(@workflow, params)

            if policy_err_msg.blank?
              flash[:notice] = 'Workflow was successfully created.'
              format.html { redirect_to workflow_url(@workflow) }
            else
              flash[:notice] = "Workflow was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
              format.html { redirect_to :controller => 'workflows', :id => @workflow, :action => "edit" }
            end
          else
            format.html { render :action => "new" }
          end
        end
      end
    end
  end
  
  # POST /workflows/1;create_version
  def create_version
    # remove protected columns
    if params[:workflow]
      [:contribution, :contributor_id, :contributor_type, :image, :created_at, :updated_at, :version].each do |column_name|
        params[:workflow].delete(column_name)
      end
    end
    
    # remove owner only columns
    unless @workflow.contribution.owner?(current_user)
      [:unique_name, :license].each do |column_name|
        params[:workflow].delete(column_name)
      end
    end

    # don't create new workflow version if no file has been selected
    if params[:workflow][:scufl].size == 0
      flash[:error] = "Please select a workflow file to upload."
      redirect_to :action => :new_version
    else
      respond_to do |format|
        scufl = params[:workflow][:scufl]

        scufl_first_k = scufl.read(1024)
        scufl.rewind

        # if first Kb of uploaded scufl contains a '<scufl>' tag then it is probably an XML workflow and can be processed
        if scufl_first_k !~ %r{<[^<>]*scufl[^<>]*>}
          flash[:error] = "File must be a Taverna workflow. Please select a workflow file."
          format.html { redirect_to :action => :new_version }
        else
          # process scufl if it's there
          unless scufl.nil?

            # create new scufl model
            scufl_model = Scufl::Parser.new.parse(scufl.read)
            scufl.rewind
        
            @workflow.body = scufl_model.description.description

            # create new diagrams and append new version number to filename
            @workflow.create_workflow_diagrams(scufl_model, "#{@workflow.current_version.to_i + 1}")
        
            cb = ContentBlob.new(:data => scufl.read)
            cb.save
            @workflow.content_blob_id = cb.id
            @workflow.content_type = "application/vnd.taverna.scufl+xml"
          end
    
          success = @workflow.save_as_new_version(ae_some_html(params[:comments]))
      
          if success
            flash[:notice] = 'Workflow version successfully created.'
            format.html { redirect_to workflow_url(@workflow) }
          else
            flash[:error] = 'Failed to upload new version. Please report this error.'       
            format.html { render :action => :new_version }
          end
        end
      end
    end
  end

  # PUT /workflows/1
  def update
    # remove protected columns
    if params[:workflow]
      [:contribution, :contributor_id, :contributor_type, :image, :created_at, :updated_at, :version].each do |column_name|
        params[:workflow].delete(column_name)
      end
    end
    
    # remove owner only columns
    unless @workflow.contribution.owner?(current_user)
      [:unique_name, :license].each do |column_name|
        params[:workflow].delete(column_name)
      end
    end
    
    # Remove sculf in case (since scufl can never be updated, only new versions can be uploaded (see seperate actions for that)
    params[:workflow].delete('scufl') if params[:workflow][:scufl]
    
    respond_to do |format|
      if @workflow.update_attributes(params[:workflow])

        if params[:workflow][:tag_list]
          @workflow.refresh_tags(convert_tags_to_gem_format(params[:workflow][:tag_list]), current_user)
        end

        policy_err_msg = update_policy(@workflow, params)
        update_credits(@workflow, params)
        update_attributions(@workflow, params)

        if policy_err_msg.blank?
          flash[:notice] = 'Workflow was successfully updated.'
          format.html { redirect_to workflow_url(@workflow) }
        else
          flash[:error] = policy_err_msg
          format.html { redirect_to :controller => 'workflows', :id => @workflow, :action => "edit" }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # PUT /workflows/1;update_version
  def update_version
    workflow_title = @workflow.title
    
    if params[:version]
      success = @workflow.update_version(params[:version], :title => params[:workflow][:title], :body => params[:workflow][:body])
    else
      success = false;
    end
    
    respond_to do |format|
      if success
        flash[:notice] = "Workflow version #{params[:version]}: \"#{workflow_title}\" has been updated"
        format.html { redirect_to(workflow_url(@workflow) + "?version=#{params[:version]}") }
      else
        flash[:error] = "Failed to update Workflow version. Please report this."
        if params[:version]
          format.html { redirect_to(workflow_url(@workflow) + "?version=#{params[:version]}") }
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
      
      if workflow.authorized?(action_name, (logged_in? ? current_user : nil))
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
        
        @named_download_url = url_for :action => 'named_download',
                                      :id => @workflow.id, 
                                      :version => @viewing_version_number.to_s,
                                      :name => "#{@viewing_version.unique_name}.xml"
                                      
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
  
  def check_is_owner
    if @workflow
      error("You are not authorised to manage this Workflow", "") unless @workflow.owner?(current_user)
    end
  end
  
  def create_workflow(wf)
    scufl_model = Scufl::Parser.new.parse(wf[:scufl].read)
    wf[:scufl].rewind

    rtn = Workflow.new(:content_blob => ContentBlob.new(:data => wf[:scufl].read),
                       :content_type => "application/vnd.taverna.scufl+xml",
                       :contributor_id => wf[:contributor_id], 
                       :contributor_type => wf[:contributor_type],
                       :body => scufl_model.description.description,
                       :license => wf[:license])
                       
    rtn.create_workflow_diagrams(scufl_model, "1")
    
    return rtn
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

end

