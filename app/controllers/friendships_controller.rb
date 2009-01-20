# myExperiment: app/controllers/friendships_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class FriendshipsController < ApplicationController
  before_filter :login_required
  
  before_filter :check_user_present # only allow actions on friendships as on nested resources
  
  before_filter :find_friendships, :only => [:index]
  before_filter :find_friendship_auth, :only => [:show, :accept, :edit, :update, :destroy]

  # declare sweepers and which actions should invoke them
  cache_sweeper :friendship_sweeper, :only => [ :create, :accept, :update, :destroy ]
  
  # POST /users/1/friendships/1/accept
  # POST /friendships/1/accept
  def accept
    friend = User.find(@friendship.friend_id)
    
    # a notification message will be delivered to the the requestor anyway;
    # it may contain a personal note, if any was supplied
    from_id = friend.id
    to_id = @friendship.user_id
    subject = friend.name + " is now your friend!" 
    body = "<strong><i>Personal message from #{friend.name}:</i></strong><hr/>"
    
    if params[:accept_msg] && !params[:accept_msg].blank?
      body += ae_some_html(params[:accept_msg])
    else
      body += "NONE"
    end
    body += "<hr/>"

    # the message will appear as 'deleted-by-sender', because the owner of the account effectively didn't send it,
    # so there is no reason for showing this message in their 'sent messages' folder
    message = Message.new( :from => from_id, :to => to_id, :subject => subject, :body => body, :reply_id => nil, :read_at => nil, :deleted_by_sender => true )
    message.save
    
    respond_to do |format|
      if @friendship.accept!
        flash[:notice] = 'Friendship was successfully accepted.'
        format.html { redirect_to friendships_url(current_user.id) }
      else
        error("Friendship already accepted", "already accepted")
      end
    end
  end
  
  # GET /users/1/friendships
  # GET /friendships
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /users/1/friendships/1
  # GET /friendships/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET users/1/friendships/new
  # GET /friendships/new
  def new
    unless params[:user_id] and params[:user_id].to_i != current_user.id.to_i
      @friendship = Friendship.new(:user_id => current_user.id)
    else
      @friendship = Friendship.new(:user_id => current_user.id)
      
      if params[:user_id] and (@friend = User.find(:first, params[:user_id]))
        @friendship.friend = @friend
      else
        params[:user_id] = nil
      end
    end
  end

  # GET /users/1/friendships/1;edit
  # GET /friendships/1;edit
  def edit
    
  end

  # POST /users/1/friendships
  # POST /friendships
  def create
    friendship_already_exists = Friendship.find_by_user_id_and_friend_id(params[:friendship][:user_id], params[:friendship][:friend_id]) || Friendship.find_by_user_id_and_friend_id(params[:friendship][:friend_id], params[:friendship][:user_id])
    if (@friendship = Friendship.new(params[:friendship]) unless friendship_already_exists )
      # set initial datetime
      @friendship.accepted_at = nil
      if @friendship.message.blank?
        @friendship.message = nil
      end

      respond_to do |format|
        if @friendship.save
          
          begin
            friend = @friendship.friend
            Notifier.deliver_friendship_request(friend, @friendship.user.name, @friendship, base_host) if friend.send_notifications?
          rescue Exception => e
            puts "ERROR: failed to send Friendship Request email notification. Friendship ID: #{@friendship.id}"
            puts "EXCEPTION:" + e
            logger.error("ERROR: failed to send Friendship Request email notification. Friendship ID: #{@friendship.id}")
            logger.error("EXCEPTION:" + e)
          end
          
          flash[:notice] = 'Friendship was successfully requested.'
          format.html { redirect_to user_friendship_url(current_user.id, @friendship) }
        else
          format.html { render :action => "new" }
        end
      end
    else
      error("Friendship not created (already exists)", "not created, already exists")
    end
  end

  # PUT /users/1/friendships/1
  # PUT /friendships/1
  def update
    # no spoofing of acceptance
    params[:friendship].delete('accepted_at') if params[:friendship][:accepted_at]
    
    respond_to do |format|
      if @friendship.update_attributes(params[:friendship])
        flash[:notice] = 'Friendship was successfully updated.'
        format.html { redirect_to friendship_url(@friendship.user_id, @friendship) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE users/1/friendships/1
  # DELETE /friendships/1
  def destroy
    friend_id = current_user.id # as it's the current user who's deleting the friendship
    friend = User.find(friend_id)
    
    # a notification message will be delivered to the the requestor anyway;
    # it may contain a personal note, if any was supplied
    from_id = friend_id
    to_id = (@friendship.friend_id == friend_id ? @friendship.user_id : @friendship.friend_id) 
    rejection = (@friendship.accepted_at.nil?) ? true : false
    
    # the same method ('destroy') works when friendship is rejected
    # or removed after being accepted previously
    if rejection
      subject = friend.name + " has rejected your friendship request" 
      body = "<strong><i>Personal message from #{friend.name}:</i></strong><hr/>"
    
      if params[:reject_msg] && !params[:reject_msg].blank?
        body += ae_some_html(params[:reject_msg])
      else
        body += "NONE"
      end
      body += "<hr/>"
    else
      subject = User.find(from_id).name + " has removed you from their friends list"
      body = "User: <a href='#{user_url(from_id)}'>#{friend.name}</a>" +
             "<br/><br/>If you want to contact this user directly, just reply to this message."
    end
    
    # the message will appear as 'deleted-by-sender', because the owner of the account effectively didn't send it,
    # so there is no reason for showing this message in their 'sent messages' folder
    message = Message.new( :from => from_id, :to => to_id, :subject => subject, :body => body, :reply_id => nil, :read_at => nil, :deleted_by_sender => true )
    message.save
    
    @friendship.destroy

    respond_to do |format|
      flash[:notice] = "Friendship was successfully deleted"
      format.html { redirect_to(params[:return_to] ? params[:return_to] : user_friendships_url(friend_id)) }
    end
  end
  
protected

  # checks that the url contains an id of the user,
  # so enforcing the use of nested links
  def check_user_present
    if params[:user_id].blank?
      flash.now[:error] = "Invalid URL"
      redirect_to friendships_url(current_user.id)
      return false
    end
  end

  def find_friendships
    if params[:user_id].to_i == current_user.id.to_i
      begin
        @user = User.find(params[:user_id])
    
        @friendships = @user.friendships
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      error("You are not authorised to view other users' friendships", "")
    end
  end

  def find_friendship
    if params[:user_id]
      begin
        @user = User.find(params[:user_id])
    
        begin
          @friendship = Friendship.find(params[:id], :conditions => ["friend_id = ?", @user.id])
        rescue ActiveRecord::RecordNotFound
          error("Friendship not found", "is invalid")
        end
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      begin
        @friendship = Friendship.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error("Friendship not found", "is invalid")
      end
    end
  end
  
  def find_friendship_auth
    begin
      begin
        # find the friendship first
        @friendship = Friendship.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ActiveRecord::RecordNotFound, "Friendship not found"
      end
      
      # now go through different actions and check which links (including user_id in the link) are allowed
      not_auth = false
      case action_name.to_s.downcase
        when "show" # link - just the current user id, but can be "friend" or "user" in the friendship
          unless params[:user_id].to_i == current_user.id.to_i && ([@friendship.user_id, @friendship.friend_id].include? current_user.id)
            not_auth = true
          end
        when "destroy" # link - just the friend id, but current user can be "friend" or "user" in the friendship
          unless params[:user_id].to_i == @friendship.friend_id.to_i && ([@friendship.user_id, @friendship.friend_id].include? current_user.id)
            not_auth = true
          end
        else # link - just the current user id, and it should be "friend" in the friendship ("accept" for example)
          unless params[:user_id].to_i == current_user.id.to_i && current_user.id == @friendship.friend_id
            not_auth = true
          end
      end
      
      # check if we had any errors
      if not_auth
        raise ActiveRecord::RecordNotFound, "You are not authorised to view other users' friendships"
      end
      
    rescue ActiveRecord::RecordNotFound => exc
      error(exc.message, "")
    end
  end
  
private
  
  def error(notice, message)
    flash[:error] = notice
    (err = Friendship.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to friendships_url(current_user.id) }
    end
  end
end
