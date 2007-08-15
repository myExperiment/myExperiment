class UsersController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :new, :create]
  
  before_filter :find_users, :only => [:index]
  before_filter :find_user, :only => [:show]
  before_filter :find_user_auth, :only => [:edit, :update, :destroy]
  
  # GET /users
  # GET /users.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @users.to_xml }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @user.to_xml }
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1;edit
  def edit
    
  end

  # POST /users
  # POST /users.xml
  def create
    if params[:user][:username] && params[:user][:password] && params[:user][:password_confirmation]
      params[:user].delete("openid_url") if params[:user][:openid_url] # strip params[:user] of it's openid_url if username and password is provided
    end
    
    params[:user][:name] ||= "Joe Bloggs BSc (CHANGE ME!!)" # initializes username (if one isn't entered)
    
    @user = User.new(params[:user])
    
    respond_to do |format|
      if @user.save
        # log user in after succesful create
        #session[:user_id] = @user.id
        self.current_user = @user
        
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to user_url(@user) }
        format.xml  { head :created, :location => user_url(@user) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors.to_xml }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    # openid url's must be validated and updated separately
    params.delete("openid_url") if params[:openid_url]
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to user_url(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors.to_xml }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user.destroy
    
    # the user MUST be logged in to destroy their account
    # it is important to log them out afterwards or they'll 
    # receive a nasty error message..
    session[:user_id] = nil
    
    respond_to do |format|
      flash[:notice] = 'User was successfully destroyed'
      format.html { redirect_to users_url }
      format.xml { head :ok }
    end
  end
  
protected

  def find_users
    @users = User.find(:all, :order => "created_at DESC")
  end

  def find_user
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("User not found", "is invalid (not owner)")
    end
  end

  def find_user_auth
    begin
      @user = User.find(params[:id], :conditions => ["id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("User not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private

  def error(notice, message)
    flash[:notice] = notice
    (err = User.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to users_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
