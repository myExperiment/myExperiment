# myExperiment: app/controllers/networks_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class NetworksController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :search, :all]
  
  before_filter :find_networks, :only => [:index, :all]
  before_filter :find_network, :only => [:membership_request, :show, :comment, :comment_delete, :tag]
  before_filter :find_network_auth, :only => [:membership_invite, :edit, :update, :destroy]
  
  # GET /networks;search
  # GET /networks.xml;search
  def search

    @query = params[:query]
    
    @networks = SOLR_ENABLE ? Network.find_by_solr(@query, :limit => 100).results : []
    
    respond_to do |format|
      format.html # search.rhtml
      format.xml  { render :xml => @networks.to_xml }
    end
  end
  
  # GET /networks/1;membership_invite
  def membership_invite
            
    if (@membership = Membership.new(:user_id => params[:user_id], :network_id => @network.id) unless Membership.find_by_user_id_and_network_id(params[:user_id], @network.id) or Network.find(@network.id).owner? params[:user_id])
      
      @membership.user_established_at = nil
      @membership.network_established_at = nil
        
      respond_to do |format|
        if @membership.save
  
          @membership.network_establish!
          
          begin
            user = @membership.user
            Notifier.deliver_membership_invite(user, @membership.network, base_host) if user.send_notifications?
          rescue
            puts "ERROR: failed to send Membership Invite email notification. Membership ID: #{@membership.id}"
            logger.error("ERROR: failed to send Membership Invite email notification. Membership ID: #{@membership.id}")
          end
  
          flash[:notice] = 'An invitation has been sent to the User.'
          format.html { redirect_to group_url(@network) }
        else
          flash[:error] = 'Failed to send invitation to User. Please try again or report this.'
          format.html { redirect_to group_url(@network) }
        end
      end
    else
      error("Membership invite not created (already exists)", "not created, already exists")
    end
  end
  
  # GET /networks/1;membership_request
  def membership_request
    redirect_to :controller => 'memberships', 
                :action => 'new', 
                :user_id => current_user.id,
                :network_id => @network.id
  end
  
  # GET /networks
  # GET /networks.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @networks.to_xml }
    end
  end
  
  # GET /networks/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end

  # GET /networks/1
  # GET /networks/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @network.to_xml }
    end
  end

  # GET /networks/new
  def new
    @network = Network.new(:user_id => current_user.id)
  end

  # GET /networks/1;edit
  def edit
    
  end

  # POST /networks
  # POST /networks.xml
  def create
    @network = Network.new(params[:network])

    respond_to do |format|
      if @network.save
        if params[:network][:tag_list]
          @network.tags_user_id = current_user
          @network.tag_list = convert_tags_to_gem_format params[:network][:tag_list]
          @network.update_tags
        end
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to group_url(@network) }
        format.xml  { head :created, :location => group_url(@network) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @network.errors.to_xml }
      end
    end
  end

  # PUT /networks/1
  # PUT /networks/1.xml
  def update
    respond_to do |format|
      if @network.update_attributes(params[:network])
        refresh_tags(@network, params[:network][:tag_list], current_user) if params[:network][:tag_list]
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to group_url(@network) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @network.errors.to_xml }
      end
    end
  end

  # DELETE /networks/1
  # DELETE /networks/1.xml
  def destroy
    @network.destroy

    respond_to do |format|
      flash[:notice] = 'Group was successfully deleted.'
      format.html { redirect_to groups_url }
      format.xml  { head :ok }
    end
  end
  
  # POST /networks/1;comment
  # POST /networks/1.xml;comment
  def comment
    text = params[:comment][:comment]
    
    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @network.comments << comment
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @network } }
      format.xml { render :xml => @network.comments.to_xml }
    end
  end
  
  # DELETE /networks/1;comment_delete
  # DELETE /networks/1.xml;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type.downcase == 'network' and comment.commentable_id == @network.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @network } }
      format.xml { render :xml => @network.comments.to_xml }
    end
  end
  
  # POST /networks/1;tag
  # POST /networks/1.xml;tag
  def tag
    @network.tags_user_id = current_user
    @network.tag_list = "#{@network.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @network.update_tags # hack to get around acts_as_versioned
    
    expire_fragment(:controller => 'groups', :action => 'all_tags')
    expire_fragment(:controller => 'sidebar_cache', :action => 'tags', :part => 'most_popular_tags')
    
    respond_to do |format|
      format.html { render :partial => "tags/tags_box_inner", :locals => { :taggable => @network, :owner_id => @network.user_id } }
      format.xml { render :xml => @workflow.tags.to_xml }
    end
  end
  
protected

  def find_networks
    if params[:user_id]
      @networks = Network.find(:all, 
                               :conditions => ["user_id = ?", params[:user_id]], 
                               :order => "title ASC",
                               :page => { :size => 20, 
                                          :current => params[:page] })
    else  
      @networks = Network.find(:all, 
                               :order => "title ASC",
                               :page => { :size => 20, 
                                          :current => params[:page] })
    end
  end

  def find_network
    begin
      @network = Network.find(params[:id])
      @network_url = url_for :only_path => false,
                             :host => base_host,
                             :id => @network.id
    rescue ActiveRecord::RecordNotFound
      error("Network not found", "is invalid (not owner)")
    end 
  end

  def find_network_auth
    begin
      @network = Network.find(params[:id], :conditions => ["user_id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("Network not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private

  def error(notice, message)
    flash[:notice] = notice
    (err = Network.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to groups_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
