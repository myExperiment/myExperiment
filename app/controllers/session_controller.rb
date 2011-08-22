# myExperiment: app/controllers/session_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'uri'
require 'openid'
require 'openid/store/filesystem'

class SessionController < ApplicationController

  # declare sweepers and which actions should invoke them
  cache_sweeper :user_sweeper, :only => [ :create ]

  # GET /session/new
  # new renders new.rhtml
  
  # POST /session
  def create
    # record return_to address if required
    session[:return_to] = request.env['HTTP_REFERER'] unless session[:return_to] and !session[:return_to].empty?
    
    if using_open_id?
      open_id_authentication
    else
      password_authentication
    end
  end
  
  # DELETE /session
  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session # clears session[:return_to]
    #flash[:notice] = "You have been logged out. Thank you for using #{Conf.sitename}!"
    redirect_to ''
  end
  
  # handle the openid server response
  def complete

    current_url = url_for(:action => 'complete', :only_path => false)
    parameters = params.reject{|k,v|request.path_parameters[k]}

    response = consumer.complete(parameters, current_url)
    
    if response.class == OpenID::Consumer::FailureResponse

      if response.identity_url
        failed_login("Verification of \"#{response.identity_url}\" failed.")
      else
        failed_login("Verification failed.")
      end

      return
    end

    redirect_to_edit_user = false
    
    # create user object if one does not exist
    unless @user = User.find(:first, :conditions => ["openid_url = ?", response.identity_url])
      @user = User.new(:openid_url => response.identity_url, :name => response.identity_url, :activated_at => Time.now, :last_seen_at => Time.now)
      redirect_to_edit_user = @user.save
    end

    # storing both the openid_url and user id in the session for for quick
    # access to both bits of information.  Change as needed.
    self.current_user = @user

    flash[:notice] = "Logged in as #{@user.name}"
     
    if redirect_to_edit_user == true
      redirect_to url_for(:controller => 'users', :action => 'edit', :id => self.current_user)
    else
      successful_login(self.current_user)
    end
  end

  protected
  
    def password_authentication
      if params[:session]
        login, password = params[:session][:username], params[:session][:password]

        self.current_user = User.authenticate(login, password)
        if logged_in?
          if params[:session][:remember_me] == "1"
            self.current_user.remember_me
            cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
          end
          successful_login(self.current_user)
        else
          failed_login('Invalid username or password')
        end
      else
        failed_login('Invalid request')
      end
    end

    def open_id_authentication
      openid_url = params[:openid_url]
      
      begin
        if request.post?
          request = consumer.begin(openid_url)

          return_to = url_for(:action=> 'complete')
          trust_root = url_for(:controller=>'')
          
          url = request.redirect_url(trust_root, return_to)
          redirect_to(url)
          return
        end
      rescue OpenID::DiscoveryFailure
        failed_login("Couldn't locate the OpenID server.  Please check your OpenID URL.")
      rescue RuntimeError, Timeout::Error => e
        if e.class == Timeout::Error
          failed_login("Could not contact your OpenID server.")
        else
          failed_login("An unknown error occurred. Please check your OpenID url and that you are connected to the internet.")
        end
      end
    end

  private
  
    def successful_login(user)
      # update "last seen" attribute
      user.update_attribute(:last_seen_at, Time.now)
      respond_to do |format|
        flash[:notice] = "Logged in successfully. Welcome to #{Conf.sitename}!"
        home_url = url_for(:controller => 'home')
        format.html { session[:return_to] and URI.parse(session[:return_to]).path == '/' ? redirect_to(home_url) : redirect_back_or_default(home_url) }
      end
    end

    def failed_login(message)
      respond_to do |format|
        flash.now[:error] = message
        format.html { render :action => 'new' }
      end
    end
    
  # Get the OpenID::Consumer object.
  def consumer
    # create the OpenID store for storing associations and nonces,
    # putting it in your app's db directory
    store_dir = Pathname.new(RAILS_ROOT).join('db').join('openid-store')
    store = OpenID::Store::Filesystem.new(store_dir)

    return OpenID::Consumer.new(session, store)
  end
end
