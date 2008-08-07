# myExperiment: app/controllers/memberships_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class MembershipsController < ApplicationController
  before_filter :login_required
  
  before_filter :check_user_present # only allow actions on memberships as on nested resources
  
  before_filter :find_memberships, :only => [:index]
  before_filter :find_membership_auth, :only => [:show, :accept, :edit, :update, :destroy]
  
  before_filter :invalidate_listing_cache, :only => [:accept, :update, :destroy]
  
  # POST /users/1/memberships/1;accept
  # POST /memberships/1;accept
  def accept
    # a notification message will be delivered to the the requestor anyway;
    # it may contain a personal note, if any was supplied
    group = Network.find(@membership.network_id)
    invite = @membership.is_invite?
      
    from_id = invite ? @membership.user_id : group.user_id
    to_id = invite ? group.user_id : @membership.user_id
    subject = User.find(from_id).name + " has accepted your membership " + (invite ? "invite" : "request") + " for '" + group.title + "' group" 
    body = "<strong><i>Personal message from " + (invite ? "user" : "group admin") + ":</i></strong><hr/>"
    if params[:accept_msg] && !params[:accept_msg].blank?
      body += ae_some_html(params[:accept_msg])
    else
      body += "NONE"
    end
    body += "<hr/>"
      
    message = Message.new( :from => from_id, :to => to_id, :subject => subject, :body => body, :reply_id => nil, :read_at => nil )
    message.save
        
    respond_to do |format|
      if @membership.accept!
        flash[:notice] = 'Membership was successfully accepted.'
        format.html { redirect_to group_url(@membership.network_id) }
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
      if @membership.message.blank?
        @membership.message = nil
      end
      
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
              Notifier.deliver_membership_request(user, network, @membership, base_host) if network.owner.send_notifications?
            rescue Exception => e
              puts "ERROR: failed to send Membership Request email notification. Membership ID: #{@membership.id}"
              puts "EXCEPTION:" + e
              logger.error("ERROR: failed to send Membership Request email notification. Membership ID: #{@membership.id}")
              logger.error("EXCEPTION:" + e)
            end
            
            flash[:notice] = 'Membership was successfully requested.'
          end

          format.html { redirect_to membership_url(current_user.id, @membership) }
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
    
    # a notification message will be delivered to the the requestor anyway;
    # it may contain a personal note, if any was supplied
    group = Network.find(network_id)
    invite = @membership.is_invite?
    rejection = (@membership.network_established_at.nil? || @membership.user_established_at.nil?) ? true : false
      
    # the same method ('destroy') works when membership is rejected
    # or removed after being accepted previously
    if rejection
      # if this is rejection, then just group admin can do this action, so
      # the message would go from group admin to the requesting-user
      from_id = invite ? @membership.user_id : group.user_id
      to_id = invite ? group.user_id : @membership.user_id
      
      subject = User.find(from_id).name + " has rejected your membership " + (invite ? "invite" : "request") + " for '" + group.title + "' group"
      body = "<strong><i>Personal message from " + (invite ? "user" : "group admin") + ":</i></strong><hr/>"
      
      if params[:reject_msg]  && !params[:reject_msg].blank?
        body += ae_some_html(params[:reject_msg])
      else
        body += "NONE"
      end
      body += "<hr/>"
    else
      # membership was cancelled, so the message goes from the current user
      # (who can be either admin or a former group member) to the 'other side' of the membership;
      # NB! subject and body should change accordingly!
      from_id = current_user.id
      from_user = User.find(from_id)
      to_id = (@membership.network.owner.id == from_id ? @membership.user_id : @membership.network.owner.id)
      
      if from_id == @membership.user_id
        subject = from_user.name + " has left the '" + group.title + "' group that you manage"
        body = "User: <a href='#{user_url(from_id)}'>#{from_user.name}</a>" +
               "<br/><br/>If you want to contact this user directly, just reply to this message."
      else  
        subject = from_user.name + " has removed you from '" + group.title + "' group"
        body = "Group: <a href='#{url_for :controller => 'networks', :action => 'show', :id => @membership.network_id}'>#{@membership.network.title}</a>" + 
               "<br/>Admin: <a href='#{user_url(@membership.network.owner.id)}'>#{@membership.network.owner.name}</a>" +
               "<br/><br/>If you want to contact the administrator of the group directly, just reply to this message."
      end
    end
    
      
    message = Message.new( :from => from_id, :to => to_id, :subject => subject, :body => body, :reply_id => nil, :read_at => nil )
    message.save
    
    
    @membership.destroy

    respond_to do |format|
      flash[:notice] = "Membership successfully deleted"
      format.html { redirect_to (params[:return_to] ? params[:return_to] : group_path(network_id)) }
    end
  end
  
protected

  # checks that the url contains an id of the user,
  # so enforcing the use of nested links
  def check_user_present
    if params[:user_id].blank?
      flash.now[:error] = "Invalid URL"
      redirect_to memberships_url(current_user.id)
      return false
    end
  end

  def find_memberships
    if params[:user_id].to_i == current_user.id.to_i
      begin
        @user = User.find(params[:user_id])
    
        @memberships = @user.memberships
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      error("You are not authorised to view other users' memberships", "")
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
    begin
      begin
        # find the membership first
        @membership = Membership.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ActiveRecord::RecordNotFound, "Membership not found"
      end
      
      # now go through different actions and check which links (including user_id in the link) are allowed
      not_auth = false
      case action_name.to_s.downcase
        when "accept"
          # Either the owner or the user can approve, 
          # depending on who initiated it (link is for current user's id only)
          if @membership.user_established_at == nil
            unless @membership.user_id == current_user.id && params[:user_id].to_i == @membership.user_id
              not_auth = true;
            end
          elsif @membership.network_established_at == nil
            unless @membership.network.owner.id == current_user.id && params[:user_id].to_i == @membership.network.owner.id
              not_auth = true;
            end
          end
        when "show", "destroy"
          # Only the owner of the network OR the person who the membership is for can view/delete memberships;
          # link - just user to whom the membership belongs
          unless ([@membership.network.owner.id, @membership.user_id].include? current_user.id) && @membership.user_id == params[:user_id].to_i 
            not_auth = true
          end
        else
          # don't allow anything else, for now
          not_auth = true
      end
      
      
      # check if we had any errors
      if not_auth
        raise ActiveRecord::RecordNotFound, "You are not authorised to view other users' memberships"
      end
      
    rescue ActiveRecord::RecordNotFound => exc
      error(exc.message, "")
    end
    
  end
  
  def invalidate_listing_cache
    if @membership
      expire_fragment(:controller => 'groups_cache', :action => 'listing', :id => @membership.network_id)
    end
  end
  
private
  
  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Membership.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to memberships_url(current_user.id) }
    end
  end
  
end
