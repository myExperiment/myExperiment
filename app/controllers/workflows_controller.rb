# myExperiment: app/controllers/workflows_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class WorkflowsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :download, :named_download, :search, :all]
  
  before_filter :find_workflows, :only => [:all]
  before_filter :find_workflows_rss, :only => [:index]
  before_filter :find_workflow_auth, :except => [:search, :index, :new, :create, :all]
  
  before_filter :check_is_owner, :only => [:edit, :update]
  
  before_filter :invalidate_listing_cache, :only => [:show, :download, :named_download, :update, :update_version, :comment, :comment_delete, :rate, :tag, :destroy, :destroy_version]
  before_filter :invalidate_tags_cache, :only => [:create, :update, :delete, :tag]
  
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
      format.html { redirect_to workflow_url(@workflow) }
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
    
    send_data(@viewing_version.scufl, :filename => @viewing_version.unique_name + ".xml", :type => "application/vnd.taverna.scufl+xml")
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

    @sharing_mode  = 1
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

    params[:workflow][:contributor_type], params[:workflow][:contributor_id] = "User", current_user.id
    
    # create workflow using helper methods
    @workflow = create_workflow(params[:workflow])
    
    respond_to do |format|
      if @workflow.save
        if params[:workflow][:tag_list]
          @workflow.refresh_tags(convert_tags_to_gem_format(params[:workflow][:tag_list]), current_user)
        end
                
        @workflow.contribution.update_attributes(params[:contribution])

        update_policy(@workflow, params)
        
        # Credits and Attributions:
        update_credits(@workflow, params)
        update_attributions(@workflow, params)

        flash[:notice] = 'Workflow was successfully created.'
        format.html { redirect_to workflow_url(@workflow) }
      else
        format.html { render :action => "new" }
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
    
    respond_to do |format|
      scufl = params[:workflow][:scufl]
      
      # process scufl if it's there
      unless scufl.nil?

        # create new scufl model
        scufl_model = Scufl::Parser.new.parse(scufl.read)
        scufl.rewind
        
        @workflow.title, @workflow.unique_name = determine_title_and_unique(scufl_model)
        @workflow.body = scufl_model.description.description

        # create new diagrams and append new version number to filename
        create_workflow_diagrams(@workflow, scufl_model, "#{@workflow.unique_name}_#{@workflow.current_version.to_i + 1}")
          
        @workflow.scufl = scufl.read
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
      workflow.scufl = nil unless workflow.authorized?("download", (logged_in? ? current_user : nil))
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
        @viewing_version.scufl = nil unless @authorised_to_download
        @workflow.scufl = nil unless @authorised_to_download
          
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
  
  def invalidate_listing_cache
    if @workflow
      expire_fragment(:controller => 'workflows_cache', :action => 'listing', :id => @workflow.id)
    end
  end
  
  def invalidate_tags_cache
    expire_fragment(:controller => 'workflows', :action => 'all_tags')
    expire_fragment(:controller => 'sidebar_cache', :action => 'tags', :part => 'most_popular_tags')
  end
  
  def determine_title_and_unique(scufl_model)
    salt = rand 32768
    return scufl_model.description.title.blank? ? ["untitled", "untitled_#{salt}"] : [scufl_model.description.title,  "#{scufl_model.description.title.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"]
  end

  def create_workflow(wf)
    scufl_model = Scufl::Parser.new.parse(wf[:scufl].read)
    wf[:scufl].rewind

    title, unique_name = determine_title_and_unique(scufl_model)
    
    rtn = Workflow.new(:scufl => wf[:scufl].read, 
                       :content_type => "application/vnd.taverna.scufl+xml",
                       :contributor_id => wf[:contributor_id], 
                       :contributor_type => wf[:contributor_type],
                       :title => title,
                       :unique_name => unique_name,
                       :body => scufl_model.description.description,
                       :license => wf[:license])
                       
    create_workflow_diagrams(rtn, scufl_model, "#{unique_name}_1")
    
    return rtn
  end
  
  def create_workflow_diagrams(workflow, scufl_model, unique_name)
    unless RUBY_PLATFORM =~ /mswin32/
      i = Tempfile.new("image")
      Scufl::Dot.new.write_dot(i, scufl_model)
      i.close(false)
      img = StringIO.new(`dot -Tpng #{i.path}`)
      svg = StringIO.new(`dot -Tsvg #{i.path}`)
      i.unlink
      img.extend FileUpload
      img.original_filename = "#{unique_name}.png"
      img.content_type = "image/png"
      svg.extend FileUpload
      svg.original_filename = "#{unique_name}.svg"
      svg.content_type = "image/svg+xml"
      
      workflow.image = img
      workflow.svg = svg
    end
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

module FileUpload
  attr_accessor :original_filename, :content_type
end
