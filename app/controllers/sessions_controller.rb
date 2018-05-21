# myExperiment: app/controllers/sessions_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'uri'
require 'open_id_authentication'
require 'openid'
require 'openid/extensions/sreg'
require 'openid/store/filesystem'

class SessionsController < ApplicationController

  # declare sweepers and which actions should invoke them
  cache_sweeper :user_sweeper, :only => [ :create ]

  # GET /session/new
  # new renders new.rhtml
  
  # POST /session
  def create
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
    redirect_to home_path
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

      # Get sreg attributes to seed new user with some pre-filled values
      registration_info = OpenID::SReg::Response.from_success_response(response).data

      name = registration_info["fullname"]

      unless name
        name = session["name"].strip
      end

      unless name && !name.empty?
        flash[:notice] ||= ""
        flash[:notice] << "Please enter your name to be displayed to other users of the site.<br/>"
        name = "OpenID User"
      end

      #email = registration_info["email"]
      #email_to_use = nil
      ## Only pre-fill the email if it doesn't already exist in the system, or this will silently fail
      #if email
      #  if !User.find_by_email(email) && !User.find_by_unconfirmed_email(email)
      #    email_to_use = email
      #  else
      #    flash[:notice] ||= ""
      #    flash[:notice] << "The email address associated with your OpenID is already in use. " +
      #                      "Please enter a unique email address in the form below."
      #  end
      #end

      @user = User.new(:openid_url => response.identity_url, :name => name, #:email => email_to_use
                       :activated_at => Time.now, :last_seen_at => Time.now)

      @user.save

      # Always redirect, user may not want to use the sreg-provided attributes
      redirect_to_edit_user = true
    end

    # storing both the openid_url and user id in the session for for quick
    # access to both bits of information.  Change as needed.
    self.current_user = @user

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

      session["name"] = params[:name]

      begin
        if request.post?
          request = consumer.begin(openid_url)

          sregreq = OpenID::SReg::Request.new
          #sregreq.request_fields([''], true) # required fields
          sregreq.request_fields(['fullname','email'], false) # optional fields

          request.add_extension(sregreq)
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
      begin
        user.update_attribute(:last_seen_at, Time.now)
      rescue
      end
      respond_to do |format|
        format.html { redirect_to(params[:return_to].blank? ? home_path : params[:return_to]) }
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
    store_dir = Pathname.new(Rails.root).join('db').join('openid-store')
    store = OpenID::Store::Filesystem.new(store_dir)

    return OpenID::Consumer.new(session, store)
  end
end
