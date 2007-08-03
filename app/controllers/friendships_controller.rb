class FriendshipsController < ApplicationController
  before_filter :authorize, :except => [:index, :show]
  
  before_filter :find_friendship, :only => [:show]
  before_filter :find_friendship_by_user_auth, :only => [:edit, :update, :destroy]
  before_filter :find_friendship_by_friend_auth, :only => [:accept]
  
  # POST /users/1/friendships/1/accept
  # POST /users/1/friendships/1/accept.xml
  # POST /friendships/1/accept
  # POST /friendships/1/accept.xml
  def accept
    respond_to do |format|
      if @friendship.accept!
        flash[:notice] = 'Friendship was successfully accepted.'
        format.html { redirect_to friendships_url(current_user.id) }
        format.xml  { head :ok }
      else
        error("Friendship already accepted", "already accepted")
      end
    end
  end
  
  # GET /users/1/friendships
  # GET /users/1/friendships.xml
  # GET /friendships
  # GET /friendships.xml
  def index
    if params[:user_id]
      @friendships = User.find(params[:user_id]).friendships
    else
      @friendships = Friendship.find(:all, :order => "created_at DESC")
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @friendships.to_xml }
    end
  end

  # GET /users/1/friendships/1
  # GET /users/1/friendships/1.xml
  # GET /friendships/1
  # GET /friendships/1.xml
  def show
    find_friendship_by_user_auth(id=params[:user_id]) if params[:user_id]

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @friendship.to_xml }
    end
  end

  # GET users/1/friendships/new
  # GET /friendships/new
  def new
    unless params[:user_id] and params[:user_id].to_i != current_user.id.to_i
      @friendship = Friendship.new(:user_id => current_user.id)
    else
      @friendship = Friendship.new(:user_id => current_user.id, :friend_id => params[:user_id])
    end
  end

  # GET /users/1/friendships/1;edit
  # GET /friendships/1;edit
  def edit
    
  end

  # POST /users/1/friendships
  # POST /users/1/friendships.xml
  # POST /friendships
  # POST /friendships.xml
  def create
    if (@friendship = Friendship.new(params[:friendship]) unless Friendship.find_by_user_id_and_friend_id(params[:friendship][:user_id], params[:friendship][:friend_id]))
      # set initial datetime
      @friendship.created_at = Time.now
      @friendship.accepted_at = nil

      respond_to do |format|
        if @friendship.save
          flash[:notice] = 'Friendship was successfully created.'
          format.html { redirect_to friendship_url(@friendship.user_id, @friendship) }
          format.xml  { head :created, :location => friendship_url(@friendship.user_id, @friendship) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @friendship.errors.to_xml }
        end
      end
    else
      error("Friendship not created (already exists)", "not created, already exists")
    end
  end

  # PUT /users/1/friendships/1
  # PUT /users/1/friendships/1.xml
  # PUT /friendships/1
  # PUT /friendships/1.xml
  def update
    respond_to do |format|
      if @friendship.update_attributes(params[:friendship])
        flash[:notice] = 'Friendship was successfully updated.'
        format.html { redirect_to friendship_url(@friendship.user_id, @friendship) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @friendship.errors.to_xml }
      end
    end
  end

  # DELETE users/1/friendships/1
  # DELETE users/1/friendships/1.xml
  # DELETE /friendships/1
  # DELETE /friendships/1.xml
  def destroy
    @friendship.destroy

    respond_to do |format|
      format.html { redirect_to friendships_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_friendship
    begin
      @friendship = Friendship.find(params[:id])
    rescue
      error("Friendship not found", "is invalid")
    end
  end

  def find_friendship_by_user_auth(id=current_user.id)
    begin
      @friendship = Friendship.find(params[:id], :conditions => ["user_id = ?", id])
    rescue ActiveRecord::RecordNotFound
      error("Friendship not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
  def find_friendship_by_friend_auth(id=current_user.id)
    begin
      @friendship = Friendship.find(params[:id], :conditions => ["friend_id = ?", id])
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
      format.xml { render :xml => err.to_xml }
    end
  end
end
