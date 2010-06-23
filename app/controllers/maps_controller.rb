# myExperiment: app/controllers/maps_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class MapsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :explore, :statistics, :search]
  
  before_filter :find_map_auth, :except => [:search, :index, :new, :create]
  
  before_filter :initiliase_empty_objects_for_new_pages, :only => [:new, :create]
  before_filter :set_sharing_mode_variables, :only => [:show, :new, :create, :edit, :update]
  
  before_filter :check_is_owner, :only => [:edit, :update]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :map_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :permission_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :bookmark_sweeper, :only => [ :destroy, :favourite, :favourite_delete ]
  cache_sweeper :tag_sweeper, :only => [ :create, :update, :tag, :destroy ]
  cache_sweeper :download_viewing_sweeper, :only => [ :show, :download, :named_download ]
  cache_sweeper :comment_sweeper, :only => [ :comment, :comment_delete ]
  cache_sweeper :rating_sweeper, :only => [ :rate ]
  
  # GET /maps
  def index
    @contributions = Contribution.contributions_list(Map, params, current_user)
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  # GET /maps/1
  def show
    if allow_statistics_logging(@map)
      @viewing = Viewing.create(:contribution => @map.contribution, :user => (logged_in? ? current_user : nil), :user_agent => request.env['HTTP_USER_AGENT'], :accessed_from_site => accessed_from_website?())
    end
    
    respond_to do |format|
      format.html # show.rhtml
    end
  end
  
  # GET /maps/new
  def new
  end
  
  # GET /maps/1;edit
  def edit
  end
  
  # POST /maps
  def create
  
    params[:map][:contributor_type], params[:map][:contributor_id] = "User", current_user.id
 
    @map = Map.new(params[:map])

    respond_to do |format|
      if @map.save
        if params[:map][:tag_list]
          @map.tags_user_id = current_user
          @map.tag_list = convert_tags_to_gem_format params[:map][:tag_list]
          @map.update_tags
        end
        # update policy
        @map.contribution.update_attributes(params[:contribution])
      
        policy_err_msg = update_policy(@map, params)
      
        update_credits(@map, params)
        update_attributions(@map, params)
      
        if policy_err_msg.blank?
          flash[:notice] = 'Map was successfully created.'
          format.html { redirect_to map_url(@map) }
        else
          flash[:notice] = "Map was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'maps', :id => @map, :action => "edit" }
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  # PUT /maps/1
  def update
    # hack for select contributor form
    if params[:contributor_pair]
      params[:contribution][:contributor_type], params[:contribution][:contributor_id] = params[:contributor_pair][:class_id].split("-")
      params.delete("contributor_pair")
    end
    
    # remove protected columns
    if params[:map]
      [:contributor_id, :contributor_type, :created_at, :updated_at].each do |column_name|
        params[:map].delete(column_name)
      end
    end
    
    respond_to do |format|
      if @map.update_attributes(params[:map])
        @map.refresh_tags(convert_tags_to_gem_format(params[:map][:tag_list]), current_user) if params[:map][:tag_list]
        
        policy_err_msg = update_policy(@map, params)
        update_credits(@map, params)
        update_attributions(@map, params)
        
        if policy_err_msg.blank?
          flash[:notice] = 'Map was successfully updated.'
          format.html { redirect_to map_url(@map) }
        else
          flash[:error] = policy_err_msg
          format.html { redirect_to :controller => 'maps', :id => @map, :action => "edit" }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # DELETE /maps/1
  def destroy
    success = @map.destroy

    respond_to do |format|
      if success
        flash[:notice] = "Map has been deleted."
        format.html { redirect_to maps_url }
      else
        flash[:error] = "Failed to delete Map. Please contact your administrator."
        format.html { redirect_to map_url(@map) }
      end
    end
  end
  
  # POST /maps/1;comment
  def comment 
    text = params[:comment][:comment]
    ajaxy = true
    
    if text.nil? or (text.length == 0)
      text = params[:comment_0_comment_editor]
      ajaxy = false
    end

    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @map.comments << comment
    end
    
    respond_to do |format|
      if ajaxy
        format.html { render :partial => "comments/comments", :locals => { :commentable => @map } }
      else
        format.html { redirect_to map_url(@map) }
      end
    end
  end
  
  # DELETE /maps/1;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type.downcase == 'map' and comment.commentable_id == @map.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @map } }
    end
  end
  
  # POST /maps/1;rate
  def rate
    if @map.contributor_type == 'User' and @map.contributor_id == current_user.id
      error("You cannot rate your own map!", "")
    else
      Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @map.class.to_s, @map.id, current_user.id])
      
      Rating.create(:rateable => @map, :user => current_user, :rating => params[:rating])
      
      respond_to do |format|
        format.html { 
          render :update do |page|
            page.replace_html "ratings_inner", :partial => "contributions/ratings_box_inner", :locals => { :contributable => @map, :controller_name => controller.controller_name }
            page.replace_html "ratings_breakdown", :partial => "contributions/ratings_box_breakdown", :locals => { :contributable => @map }
          end }
      end
    end
  end
  
  # POST /maps/1;tag
  def tag
    @map.tags_user_id = current_user # acts_as_taggable_redux
    @map.tag_list = "#{@map.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @map.update_tags # hack to get around acts_as_versioned
    
    respond_to do |format|
      format.html { 
        render :update do |page|
          unique_tag_count = @map.tags.uniq.length
          page.replace_html "mini_nav_tag_link", "(#{unique_tag_count})"
          page.replace_html "tags_box_header_tag_count_span", "(#{unique_tag_count})"
          page.replace_html "tags_inner_box", :partial => "tags/tags_box_inner", :locals => { :taggable => @map, :owner_id => @map.contributor_id } 
        end
      }
    end
  end
  
  # POST /maps/1;favourite
  def favourite
    @map.bookmarks << Bookmark.create(:user => current_user) unless @map.bookmarked_by_user?(current_user)
    
    respond_to do |format|
      flash[:notice] = "You have successfully added this item to your favourites."
      format.html { redirect_to map_url(@map) }
    end
  end
  
  # DELETE /maps/1;favourite_delete
  def favourite_delete
    @map.bookmarks.each do |b|
      if b.user_id == current_user.id
        b.destroy
      end
    end
    
    respond_to do |format|
      flash[:notice] = "You have successfully removed this item from your favourites."
      redirect_url = params[:return_to] ? params[:return_to] : map_url(@map)
      format.html { redirect_to redirect_url }
    end
  end
  
  # GET /maps/1/explore
  def explore
    respond_to do |format|
      format.html {
        @extra_head_content = "<script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;sensor=true&amp;key=#{Conf.google_maps_api_key}\" type=\"text/javascript\"></script>"
        # explore.rhtml
      }
    end
  end

  protected
  
  def find_map_auth
    begin
      map = Map.find(params[:id]) 
      if Authorization.is_authorized?(action_name, nil, map, current_user)
        @map = map
        
        @map_entry_url = url_for :only_path => false,
                            :host => base_host,
                            :id => @map.id

      else
        if logged_in? 
          error("File not found (id not authorized)", "is invalid (not authorized)")
          return false
        else
          find_map_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("File not found", "is invalid")
      return false
    end
  end
  
  def initiliase_empty_objects_for_new_pages
    if ["new", "create"].include?(action_name)
      @map = Map.new
    end
  end
  
  def set_sharing_mode_variables
    if @map
      case action_name
        when "new"
          @sharing_mode  = 0
          @updating_mode = 6
        when "create", "update"
          @sharing_mode  = params[:sharing][:class_id].to_i if params[:sharing]
          @updating_mode = params[:updating][:class_id].to_i if params[:updating]
        when "show", "edit"
          @sharing_mode  = @map.contribution.policy.share_mode
          @updating_mode = @map.contribution.policy.update_mode
      end
    end
  end
  
  def check_is_owner
    if @map
      error("You are not authorised to manage this File", "") unless @map.owner?(current_user)
    end
  end
  
  private
  
  def error(notice, message, attr=:id)
    flash[:error] = notice
     (err = Map.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to maps_url }
    end
  end
end

