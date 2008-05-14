# myExperiment: app/controllers/packs_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PacksController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :all]
  
  before_filter :find_packs, :only => [:all]
  before_filter :find_pack_auth, :except => [:index, :new, :create, :all]
  
  before_filter :invalidate_listing_cache, :only => [:show, :update, :comment, :comment_delete, :tag, :destroy]

  # GET /packs
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  # GET /packs/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end
  
  # GET /packs/1
  def show
    @viewing = Viewing.create(:contribution => @pack.contribution, :user => (logged_in? ? current_user : nil))
    
    @sharing_mode  = determine_sharing_mode(@pack)
    @updating_mode = determine_updating_mode(@pack)
    
    respond_to do |format|
      format.html # show.rhtml
    end
  end
  
  # GET /packs/new
  def new
    @pack = Pack.new
    
    @sharing_mode  = 1
    @updating_mode = 6
  end
  
  # GET /packs/1;edit
  def edit
    @sharing_mode  = determine_sharing_mode(@pack)
    @updating_mode = determine_updating_mode(@pack)
  end
  
  # POST /packs
  def create
    
    params[:pack][:contributor_type], params[:pack][:contributor_id] = "User", current_user.id
    
    @pack = Pack.new(params[:pack])
    
    respond_to do |format|
      if @pack.save
        if params[:pack][:tag_list]
          @pack.tags_user_id = current_user
          @pack.tag_list = convert_tags_to_gem_format params[:pack][:tag_list]
          @pack.update_tags
        end
        
        # update policy
        update_policy(@pack, params)
        
        flash[:notice] = 'Pack was successfully created.'
        format.html { redirect_to pack_url(@pack) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  # PUT /packs/1
  def update
    
    # remove protected columns
    if params[:pack]
      [:contributor_id, :contributor_type, :created_at, :updated_at].each do |column_name|
        params[:pack].delete(column_name)
      end
    end
    
    respond_to do |format|
      if @pack.update_attributes(params[:pack])
        @pack.refresh_tags(convert_tags_to_gem_format(params[:pack][:tag_list]), current_user) if params[:pack][:tag_list]
        update_policy(@pack, params)
        
        flash[:notice] = 'Pack was successfully updated.'
        format.html { redirect_to pack_url(@pack) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # DELETE /packs/1
  def destroy
    success = @pack.destroy

    respond_to do |format|
      if success
        flash[:notice] = "Pack has been deleted."
        format.html { redirect_to packs_url }
      else
        flash[:error] = "Failed to delete Pack. Please contact your administrator."
        format.html { redirect_to pack_url(@pack) }
      end
    end
  end
  
  # POST /packs/1;comment
  def comment 
    text = params[:comment][:comment]
    
    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @pack.comments << comment
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @pack } }
    end
  end
  
  # DELETE /packs/1;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type == 'Pack' and comment.commentable_id == @pack.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @pack } }
    end
  end
  
  # POST /packs/1;tag
  def tag
    @pack.tags_user_id = current_user # acts_as_taggable_redux
    @pack.tag_list = "#{@pack.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @pack.update_tags # hack to get around acts_as_versioned
    
    expire_fragment(:controller => 'packs', :action => 'all_tags')
    expire_fragment(:controller => 'sidebar_cache', :action => 'tags', :part => 'most_popular_tags')
    
    respond_to do |format|
      format.html { render :partial => "tags/tags_box_inner", :locals => { :taggable => @pack, :owner_id => @pack.contributor_id } }
    end
  end
  
  def new_item
    # Hack for multi level params to be treated as non null in the view
    params[:contributable] = { } if params[:contributable].nil?
    params[:remote] = { } if params[:remote].nil?
    
    # Set any initial data if provided in the url as query strings
    if params[:contributable_type]
      params[:contributable][:type] = params[:contributable_type].capitalize
      @type = 'contributable'
    end
    if params[:contributable_id]
      params[:contributable][:id] = params[:contributable_id]
      @type = 'contributable'
    end
    if params[:contributable_version]
      params[:contributable][:version] = params[:contributable_version]
      @type = 'contributable'
    end
    
    # Will render packs/new_item.rhtml
  end
  
  def create_item
    if params[:entry_type]
      @type = params[:entry_type]
      
      respond_to do |format|
        case @type
          when 'contributable'
            e = PackContributableEntry.new
            e.contributable_type = params[:contributable][:type]  # This assumes that the contributable_type returned is in internal format (eg: 'Blobs' for files).
            e.contributable_id = params[:contributable][:id]
            e.contributable_version = params[:contributable][:version]
          when 'remote'
            e = PackRemoteEntry.new
            e.title = params[:remote][:title]
            e.uri = params[:remote][:uri]
            e.alternate_uri = params[:remote][:alternate_uri]
        end
        
        e.pack = @pack
        e.user = current_user
        e.comment = params[:comment]
        
        if e.save
          flash[:notice] = 'Item succesfully added to pack.'
          format.html { redirect_to pack_url(@pack) }
        else
          # Hack for multi level params to be treated as non null in the view
          params[:contributable] = { } if params[:contributable].nil?
          params[:remote] = { } if params[:remote].nil?
          
          flash[:error] = 'Failed to add item to pack.'
          format.html { render :action => "new_item" }
        end
      end
    end
  end
  
  def edit_item
    
  end
  
  def update_item
    
  end
  
  def destroy_item
    # Note: at this point, we are assuming that authorisation for deleting of items has been given by a before_filter method
    if params[:item_type] and params[:item_id]
      case params[:item_type].downcase
        when 'contributable' 
          i = PackContributableEntry.find(:first, :conditions => ["id = ?", params[:item_id]])
          i.destroy if i
        when 'external'
          i = PackRemoteEntry.find(:first, :conditions => ["id = ?", params[:item_id]])
          i.destroy if i
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "packs/items", :locals => { :pack => @pack, :authorised_to_edit => @authorised_to_edit } }
    end
  end
  
  protected
  
  def find_packs
    @packs = Pack.find(:all, 
                       :order => "title ASC",
                       :page => { :size => 20, 
                       :current => params[:page] })
  end
  
  def find_pack_auth
    begin
      pack = Pack.find(params[:id])
      
      if pack.authorized?(action_name, (logged_in? ? current_user : nil))
        @pack = pack
        
        @authorised_to_edit = @pack.authorized?("edit", current_user)
        
        @pack_url = url_for :only_path => false,
                            :host => base_host,
                            :id => @pack.id
      else
        error("You are not authorised to perform this action", "is not authorized")
      end
    rescue ActiveRecord::RecordNotFound
      error("Pack not found", "is invalid")
    end
  end
  
  def invalidate_listing_cache
    if @pack
      expire_fragment(:controller => 'packs_cache', :action => 'listing', :id => @pack.id)
    end
  end
  
  private
  
  def error(notice, message, attr=:id)
    flash[:notice] = notice
     (err = Pack.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to packs_url }
    end
  end
end
