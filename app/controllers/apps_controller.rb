# myExperiment: app/controllers/apps_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class AppsController < ApplicationController
  before_filter :login_required,             :except => [:index, :show, :statistics, :search, :all]
  before_filter :find_apps,                  :only   => [:all]
  before_filter :find_app_aux,               :except => [:search, :index, :new, :create, :all]
  before_filter :create_empty_object,        :only   => [:new, :create]
  before_filter :set_sharing_mode_variables, :only   => [:show, :new, :create, :edit, :update]
  before_filter :check_can_edit,             :only   => [:edit, :update]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :blob_sweeper,             :only => [ :create, :update, :destroy ]
  cache_sweeper :permission_sweeper,       :only => [ :create, :update, :destroy ]
  cache_sweeper :bookmark_sweeper,         :only => [ :destroy, :favourite, :favourite_delete ]
  cache_sweeper :tag_sweeper,              :only => [ :create, :update, :tag, :destroy ]
  cache_sweeper :comment_sweeper,          :only => [ :comment, :comment_delete ]
  cache_sweeper :rating_sweeper,           :only => [ :rate ]
  
  # GET /applications;search
  def search
    @query = params[:query] || ''
    @query.strip!
    
    @contributables = (SOLR_ENABLE && !@query.blank?) ? App.find_by_solr(@query, :limit => 100).results : []
    @total_count = (SOLR_ENABLE && !@query.blank?) ? App.count_by_solr(@query) : 0
    
    respond_to do |format|
      format.html # search.rhtml
    end
  end
  
  # GET /applications
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  # GET /applications/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end
  
  # GET /applications/1
  def show
    if allow_statistics_logging(@contributable)
      @viewing = Viewing.create(:contribution => @contributable.contribution, :user => (logged_in? ? current_user : nil), :user_agent => request.env['HTTP_USER_AGENT'], :accessed_from_site => accessed_from_website?())
    end
  end
  
  # GET /applications/new
  def new
  end
  
  # GET /applications/1;edit
  def edit
  end
  
  # POST /applications
  def create
  
    @contributable = App.new(
        :contributor => current_user,
        :title       => params[:contributable][:title],
        :description => params[:contributable][:description],
        :license     => params[:contributable][:license])

    if @contributable.save == false
      render :action => "new"
      return
    end

    if params[:contributable][:tag_list]
      @contributable.tags_user_id = current_user
      @contributable.tag_list = convert_tags_to_gem_format params[:contributable][:tag_list]
      @contributable.update_tags
    end

    # update policy
    @contributable.contribution.update_attributes(params[:contribution])
  
    policy_err_msg = update_policy(@contributable, params)
  
    update_credits(@contributable, params)
    update_attributions(@contributable, params)
  
    if policy_err_msg.blank?
      flash[:notice] = 'Application was successfully created.'
      redirect_to application_url(@contributable)
    else
      flash[:notice] = "Application was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
      redirect_to :controller => 'apps', :id => @contributable, :action => "edit"
    end
  end
  
  # PUT /applications/1
  def update
    # hack for select contributor form
    if params[:contributor_pair]
      params[:contribution][:contributor_type], params[:contribution][:contributor_id] = params[:contributor_pair][:class_id].split("-")
      params.delete("contributor_pair")
    end
    
    # remove protected columns
    if params[:contributable]
      [:contributor_id, :contributor_type, :content_type, :local_name, :created_at, :updated_at].each do |column_name|
        params[:contributable].delete(column_name)
      end
    end
    
    respond_to do |format|
      if @contributable.update_attributes(params[:contributable])
        @contributable.refresh_tags(convert_tags_to_gem_format(params[:contributable][:tag_list]), current_user) if params[:contributable][:tag_list]
        
        policy_err_msg = update_policy(@contributable, params)
        update_credits(@contributable, params)
        update_attributions(@contributable, params)
        
        if policy_err_msg.blank?
          flash[:notice] = 'Application was successfully updated.'
          format.html { redirect_to application_url(@contributable) }
        else
          flash[:error] = policy_err_msg
          format.html { redirect_to :controller => 'apps', :id => @contributable, :action => "edit" }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # DELETE /applications/1
  def destroy
    success = @contributable.destroy

    respond_to do |format|
      if success
        flash[:notice] = "Application has been deleted."
        format.html { redirect_to applications_url }
      else
        flash[:error] = "Failed to delete Application. Please contact your administrator."
        format.html { redirect_to application_url(@contributable) }
      end
    end
  end
  
  # POST /applications/1;comment
  def comment 
    text = params[:comment][:comment]
    
    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @contributable.comments << comment
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @contributable } }
    end
  end
  
  # DELETE /applications/1;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type == 'App' and comment.commentable_id == @contributable.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @contributable } }
    end
  end
  
  # POST /applications/1;rate
  def rate
    if @contributable.contributor_type == 'User' and @contributable.contributor_id == current_user.id
      error("You cannot rate your own content!", "")
    else
      Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @contributable.class.to_s, @contributable.id, current_user.id])
      
      @contributable.ratings << Rating.create(:user => current_user, :rating => params[:rating])
      
      respond_to do |format|
        format.html { 
          render :update do |page|
            page.replace_html "ratings_inner", :partial => "contributions/ratings_box_inner", :locals => { :contributable => @contributable, :controller_name => controller.controller_name }
            page.replace_html "ratings_breakdown", :partial => "contributions/ratings_box_breakdown", :locals => { :contributable => @contributable }
          end }
      end
    end
  end
  
  # POST /applications/1;tag
  def tag
    @contributable.tags_user_id = current_user # acts_as_taggable_redux
    @contributable.tag_list = "#{@contributable.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @contributable.update_tags # hack to get around acts_as_versioned
    
    respond_to do |format|
      format.html { 
        render :update do |page|
          unique_tag_count = @contributable.tags.uniq.length
          page.replace_html "mini_nav_tag_link", "(#{unique_tag_count})"
          page.replace_html "tags_box_header_tag_count_span", "(#{unique_tag_count})"
          page.replace_html "tags_inner_box", :partial => "tags/tags_box_inner", :locals => { :taggable => @contributable, :owner_id => @contributable.contributor_id } 
        end
      }
    end
  end
  
  # POST /applications/1;favourite
  def favourite
    @contributable.bookmarks << Bookmark.create(:user => current_user) unless @contributable.bookmarked_by_user?(current_user)
    
    respond_to do |format|
      flash[:notice] = "You have successfully added this item to your favourites."
      format.html { redirect_to application_url(@contributable) }
    end
  end
  
  # DELETE /applications/1;favourite_delete
  def favourite_delete
    @contributable.bookmarks.each do |b|
      if b.user_id == current_user.id
        b.destroy
      end
    end
    
    respond_to do |format|
      flash[:notice] = "You have successfully removed this item from your favourites."
      redirect_url = params[:return_to] ? params[:return_to] : application_url(@contributable)
      format.html { redirect_to redirect_url }
    end
  end
  
  protected
  
  def find_apps
    @contributables = App.find(:all, 
                       :order => "created_at DESC",
                       :page => { :size => 20, 
                       :current => params[:page] })
  end
  
  def find_app_aux
    begin
      app = App.find(params[:id])
      
      if Authorization.is_authorized?(action_name, nil, app, current_user)
        @contributable = app
        
        @contributable_entry_url = url_for :only_path => false,
                            :host => base_host,
                            :id => @contributable.id

      else
        if logged_in? 
          error("Application not found (id not authorized)", "is invalid (not authorized)")
          return false
        else
          find_app_aux if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Application not found", "is invalid")
      return false
    end
  end
  
  def create_empty_object
    @contributable = App.new
  end
  
  def set_sharing_mode_variables
    case action_name
      when "new"
        @sharing_mode  = 0
        @updating_mode = 6
      when "create", "update"
        @sharing_mode  = params[:sharing][:class_id].to_i if params[:sharing]
        @updating_mode = params[:updating][:class_id].to_i if params[:updating]
      when "show", "edit"
        @sharing_mode  = @contributable.contribution.policy.share_mode
        @updating_mode = @contributable.contribution.policy.update_mode
    end
  end

  def check_can_edit
    if @contributable && !Authorization.is_authorized?('edit', nil, @contributable, current_user)
      error("You are not authorised to manage this Application", "")
    end
  end
  
  private
  
  def error(notice, message, attr=:id)
    flash[:error] = notice
     (err = App.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to applications_url }
    end
  end
end
