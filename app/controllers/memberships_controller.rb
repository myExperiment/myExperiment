# myExperiment: app/controllers/memberships_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class MembershipsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_memberships, :only => [:index]
  before_filter :find_membership, :only => [:show]
  before_filter :find_membership_auth, :only => [:accept, :edit, :update, :destroy]
  
  before_filter :invalidate_listing_cache, :only => [:accept, :update, :destroy]
  
  # GET /users/1/memberships/1;accept
  # GET /memberships/1;accept
  def accept
    respond_to do |format|
      if @membership.accept!
        flash[:notice] = 'Membership was successfully accepted.'
        format.html { redirect_to memberships_url(current_user.id) }
      else
        error("Membership already accepted", "already accepted")
      end
    end
  end
  
  # GET /users/1/memberships
  # GET /memberships
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /users/1/memberships/1
  # GET /memberships/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /users/1/memberships/new
  # GET /memberships/new
  def new
    if params[:network_id]
      begin
        @network = Network.find(params[:network_id])
        
        @membership = Membership.new(:user_id => current_user.id, :network_id => @network.id)
      rescue ActiveRecord::RecordNotFound
        error("Group not found", "is invalid", :network_id)
      end
    else
      @membership = Membership.new(:user_id => current_user.id)
    end
  end

  # GET /users/1/memberships/1;edit
  # GET /memberships/1;edit
  def edit
    
  end

  # POST /users/1/memberships
  # POST /memberships
  def create
    # TODO: test if "user_established_at" and "network_established_at" can be hacked (ie: set) through API calls,
    # thereby creating memberships that are already 'accepted' at creation.
    if (@membership = Membership.new(params[:membership]) unless Membership.find_by_user_id_and_network_id(params[:membership][:user_id], params[:membership][:network_id]) or Network.find(params[:membership][:network_id]).owner? params[:membership][:user_id])
      
      @membership.user_established_at = nil
      @membership.network_established_at = nil
      
      respond_to do |format|
        if @membership.save
          
          # Take into account network's "auto accept" setting
          if (@membership.network.auto_accept)
            @membership.accept!
            
            begin
              user = @membership.user
              network = @membership.network
              Notifier.deliver_auto_join_group(user, network, base_host) if network.owner.send_notifications?
            rescue
              puts "ERROR: failed to send email notification for auto join group. Membership ID: #{@membership.id}"
              logger.error("ERROR: failed to send email notification for auto join group. Membership ID: #{@membership.id}")
            end
            
            flash[:notice] = 'You have successfully joined the Group.'
          else
            @membership.user_establish!
            
            begin
              user = @membership.user
              network = @membership.network
              Notifier.deliver_membership_request(user, network, base_host) if network.owner.send_notifications?
            rescue
              puts "ERROR: failed to send Membership Request email notification. Membership ID: #{@membership.id}"
              logger.error("ERROR: failed to send Membership Request email notification. Membership ID: #{@membership.id}")
            end
            
            flash[:notice] = 'Membership was successfully requested.'
          end

          format.html { redirect_to membership_url(@membership.user_id, @membership) }
        else
          format.html { render :action => "new" }
        end
      end
    else
      error("Membership not created (already exists)", "not created, already exists")
    end
  end

  # PUT /users/1/memberships/1
  # PUT /memberships/1
  def update
    # no spoofing of acceptance
    params[:membership].delete('network_established_at') if params[:membership][:network_established_at]
    params[:membership].delete('user_established_at') if params[:membership][:user_established_at]
    
    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        flash[:notice] = 'Membership was successfully updated.'
        format.html { redirect_to membership_url(@membership.user_id, @membership) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /users/1/memberships/1
  # DELETE /memberships/1
  def destroy
    network_id = @membership.network_id
    
    @membership.destroy

    respond_to do |format|
      params[:notice] = "Membership successfully deleted"
      format.html { redirect_to group_path(network_id) }
    end
  end
  
protected

  def find_memberships
    if params[:user_id]
      begin
        @user = User.find(params[:user_id])
    
        @memberships = @user.memberships
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      @memberships = Membership.find(:all, 
                                     :order => "created_at DESC",
                                     :page => { :size => 20, 
                                                :current => params[:page] })
    end
  end

  def find_membership
    if params[:user_id]
      begin
        @user = User.find(params[:user_id])
    
        begin
          @membership = Membership.find(params[:id], :conditions => ["user_id = ?", @user.id])
        rescue ActiveRecord::RecordNotFound
          error("Membership not found", "is invalid")
        end
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      begin
        @membership = Membership.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error("Membership not found", "is invalid")
      end
    end
  end
  
  def find_membership_auth
    if params[:user_id]
      begin
        membership = Membership.find(params[:id])
        
        is_error = false;
        
        if action_name.to_s == "accept"
        
          # Either the owner or the user can approve, 
          # depending on who initiated it        
          if membership.user_established_at == nil
            if membership.user_id != current_user.id
              is_error = true;
            end
          elsif membership.network_established_at == nil
            if current_user.id != membership.network.owner.id
              is_error = true;
            end
          end
          
        elsif action_name.to_s == "destroy"
          
          # Only the owner of the network OR the person who the membership is for can delete memberships
          if current_user.id != membership.network.owner.id and current_user.id != membership.user_id
            is_error = true
          end
        
        else
        
          # don't allow anything else, for now
          is_error = true;
        
        end
      
        if !is_error
          @membership = membership
        else
          error("Membership not found (id not authorized)", "is invalid", :network_id)
        end
      rescue ActiveRecord::RecordNotFound
        error("Membership not found", "is invalid")
      end
    else
      error("Membership not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
  def invalidate_listing_cache
    if @membership
      expire_fragment(:controller => 'groups_cache', :action => 'listing', :id => @membership.network_id)
    end
  end
  
private
  
  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Membership.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to memberships_url(current_user.id) }
    end
  end
end
