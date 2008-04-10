# myExperiment: app/controllers/friendships_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class FriendshipsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_friendships, :only => [:index]
  before_filter :find_friendship, :only => [:show]
  before_filter :find_friendship_auth, :only => [:accept, :edit, :update, :destroy]
  
  # GET /users/1/friendships/1/accept
  # GET /friendships/1/accept
  def accept
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
    if (@friendship = Friendship.new(params[:friendship]) unless Friendship.find_by_user_id_and_friend_id(params[:friendship][:user_id], params[:friendship][:friend_id]))
      # set initial datetime
      @friendship.accepted_at = nil

      respond_to do |format|
        if @friendship.save
          
          begin
            friend = @friendship.friend
            Notifier.deliver_friendship_request(friend, @friendship.user.name, base_host) if friend.send_notifications?
          rescue
            puts "ERROR: failed to send Friendship Request email notification. Friendship ID: #{@friendship.id}"
            logger.error("ERROR: failed to send Friendship Request email notification. Friendship ID: #{@friendship.id}")
          end
          
          flash[:notice] = 'Friendship was successfully requested.'
          format.html { redirect_to friendship_url(@friendship.friend_id, @friendship) }
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
    friend_id = @friendship.friend_id
    
    @friendship.destroy

    respond_to do |format|
      format.html { redirect_to friendships_url(friend_id) }
    end
  end
  
protected

  def find_friendships
    if params[:user_id]
      begin
        @user = User.find(params[:user_id])
    
        @friendships = @user.friendships
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      @friendships = Friendship.find(:all, 
                                     :order => "created_at DESC",
                                     :page => { :size => 20, 
                                                :current => params[:page] })
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
      if action_name.to_s == "show"
        @friendship = Friendship.find(params[:id], :conditions => ["friend_id = ? or user_id = ?", current_user.id, current_user.id])
      else
        @friendship = Friendship.find(params[:id], :conditions => ["friend_id = ?", current_user.id])
      end
    rescue ActiveRecord::RecordNotFound
      error("Friendship not found (id not authorized)", "is invalid (not named)")
    end
  end
  
private
  
  def error(notice, message)
    flash[:notice] = notice
    (err = Friendship.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to friendships_url(current_user.id) }
    end
  end
end
