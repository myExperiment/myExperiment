# myExperiment: app/controllers/users_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class UsersController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :new, :create, :search, :all, :confirm_email, :forgot_password, :reset_password]
  
  before_filter :find_users, :only => [:index, :all]
  before_filter :find_user, :only => [:show]
  before_filter :find_user_auth, :only => [:edit, :update, :destroy]
  
  # GET /users;search
  # GET /users.xml;search
  def search
    @query = params[:query] == nil ? "" : params[:query] + "~"
    
    results = User.find_with_ferret(@query, :limit => :all)
    
    # Only show activated users!
    @users = results.select { |u| u.activated? }
    
    respond_to do |format|
      format.html # search.rhtml
      format.xml  { render :xml => @users.to_xml }
    end
  end
  
  # GET /users
  # GET /users.xml
  def index
    @users.each do |user|
      user.salt = nil
      user.crypted_password = nil
    end
    
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @users.to_xml }
    end
  end
  
  # GET /users/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user.salt = nil
    @user.crypted_password = nil
    
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @user.to_xml(:except => [ :id, :username, :crypted_password, :salt, :remember_token, :remember_token_expires_at, :email, :unconfirmed_email, :activated_at, :receive_notifications, :reset_password_code, :reset_password_code_until ], 
                                                :include => [ :profile ]) }
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
    
    unless params[:user][:name]
      if params[:user][:username]
        params[:user][:name] = params[:user][:username].humanize # initializes username (if one isn't entered)
      else
        params[:user][:name] = params[:user][:openid_url]
      end
    end
    
    # Reset certain fields (to prevent injecting the values)
    params[:user][:email] = nil;
    params[:user][:email_confirmed_at] = nil
    params[:user][:activated_at] = nil
    
    @user = User.new(params[:user])
    
    respond_to do |format|
      if @user.save
        # DO NOT log in user yet, since account needs to be validated and activated first (through email).
        Mailer.deliver_confirmation_email(@user, confirmation_hash(@user.unconfirmed_email), base_host)        
        flash[:notice] = "Thank you for registering! We have sent a confirmation email to #{@user.unconfirmed_email} with instructions on how to activate your account."
        format.html { redirect_to(:action => "index") }
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
        flash[:notice] = 'You have succesfully updated your account'
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
    flash[:notice] = 'Please contact the administrator to have your account removed.'
    redirect_to :action => :index
    
    #@user.destroy
    
    # the user MUST be logged in to destroy their account
    # it is important to log them out afterwards or they'll 
    # receive a nasty error message..
    #session[:user_id] = nil
    
    #respond_to do |format|
    #  flash[:notice] = 'User was successfully destroyed'
    #  format.html { redirect_to users_url }
    #  format.xml { head :ok }
    #end
  end
  
  # GET /users/confirm_email/:hash
  # GET /users/confirm_email/:hash.xml
  # TODO: NOTE: this action is not "API safe" yet (ie: it doesnt cater for a request with an XML response)
  def confirm_email
    # NOTE: this action is used for both:
    # - new users who sign up with username/password and need to confirm their email address
    # - existing users who want to change their email address (but old email address is still active) 
        
    @users = User.find :all

    confirmed = false
    
    for user in @users
      unless user.unconfirmed_email.blank?
        # Check if hash matches user, in which case confirm the user's email
        if confirmation_hash(user.unconfirmed_email) == params[:hash]
          confirmed = user.confirm_email!
          # BEGIN DEBUG
          puts "ERRORS!" unless user.errors.empty?
          user.errors.full_messages.each { |e| puts e } 
          #END DEBUG
          if confirmed
            self.current_user = user
            confirmed = false if !logged_in?
          end
          @user = user
          break
        end
      end
    end
    
    respond_to do |format|
      if confirmed
        flash[:notice] = "Thank you for confirming your email. Your account is now active."
        format.html { redirect_to user_url(@user) }
      else
        flash[:error] = "Invalid confirmation URL"
        format.html { redirect_to(:controller => "session", :action => "new") }
      end
    end
  end
  
  # GET /users/forgot_password
  # POST /users/forgot_password
  # TODO: NOTE: this action is not "API safe" yet (ie: it doesnt cater for a request with an XML response)
  def forgot_password
    
    if request.get?
      # forgot_password.rhtml
    elsif request.post?
      user = User.find_by_email(params[:email])

      respond_to do |format|
        if user
          user.reset_password_code_until = 1.day.from_now
          user.reset_password_code =  Digest::SHA1.hexdigest( "#{user.email}#{Time.now.to_s.split(//).sort_by {rand}.join}" )
          user.save!
          Mailer.deliver_forgot_password(user, base_host)
          flash[:notice] = "Instructions on how to reset your password have been sent to #{user.email}"
          format.html { render :action => "forgot_password" }
        else
          flash[:error] = "Invalid email address: #{params[:email]}"
          format.html { render :action => "forgot_password" }
        end
      end
    end
    
  end
  
  # GET /users/reset_password
  # TODO: NOTE: this action is not "API safe" yet (ie: it doesnt cater for a request with an XML response)
  def reset_password
    user = User.find_by_reset_password_code(params[:reset_code])
    
    respond_to do |format|
      if user
        if user.reset_password_code_until && Time.now < user.reset_password_code_until
          user.reset_password_code = nil
          user.reset_password_code_until = nil
          if user.save
            self.current_user = user
            if logged_in?
              flash[:notice] = "You can reset your password here"
              format.html { redirect_to(:action => "edit", :id => user.id) }
            else
              flash[:error] = "An unknown error has occurred. We are sorry for the inconvenience. You can request another password reset here."
              format.html { render :action => "forgot_password" }
            end
          end
        else
          flash[:error] = "Your password reset code has expired"
        format.html { redirect_to(:controller => "session", :action => "new") }
        end
      else
        flash[:error] = "Invalid password reset code"
        format.html { redirect_to(:controller => "session", :action => "new") }
      end
    end 
  end
  
protected

  def find_users
    @users = User.find(:all, 
                       :order => "name ASC",
                       :page => { :size => 20, 
                                  :current => params[:page] },
                       :conditions => "activated_at IS NOT NULL")
  end

  def find_user
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("User not found", "is invalid (not owner)")
    end
    
    # TODO: if user is nil... redirect to a 404 page or provide a decent error message
    
    unless @user.activated?
      error("User not found", "is invalid (not owner)")
    end
  end

  def find_user_auth
    begin
      @user = User.find(params[:id], :conditions => ["id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("User not found (id not authorized)", "is invalid (not owner)")
    end
    
    # TODO: if user is nil... redirect to a 404 page or provide a decent error message
    
    unless @user.activated?
      error("User not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private

  def error(notice, message)
    flash[:error] = notice
    (err = User.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to users_url }
      format.xml { render :xml => err.to_xml }
    end
  end
  
  def confirmation_hash(string)
    Digest::SHA1.hexdigest(string + SECRET_WORD)
  end
end
