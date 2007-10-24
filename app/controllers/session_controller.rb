##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

require 'uri'

class SessionController < ApplicationController
  # GET /session/new
  # new renders new.rhtml
  
  # POST /session
  # POST /session.xml
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
  # DELETE /session.xml
  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session # clears session[:return_to]
    #flash[:notice] = "You have been logged out. Thank you for using myExperiment!"
    redirect_to ''
  end
  
  # handle the openid server response
  def complete
    response = consumer.complete(params)
    
    case response.status
    when OpenID::SUCCESS
      redirect_to_edit_user = false
      
      # create user object if one does not exist
      unless @user = User.find_first(["openid_url = ?", response.identity_url])
        @user = User.new(:openid_url => response.identity_url, :name => "Joe Bloggs BSc (CHANGE ME!!)", :last_seen_at => Time.now)
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
      
      return

    when OpenID::FAILURE
      if response.identity_url
        flash[:notice] = "Verification of #{CGI::escape(response.identity_url)} failed."

      else
        flash[:notice] = 'Verification failed.'
      end

    when OpenID::CANCEL
      flash[:notice] = 'Verification cancelled.'

    else
      flash[:notice] = 'Unknown response from OpenID server.'
    end
  
    failed_login(flash[:notice])
  end

  protected
  
    def password_authentication
      login, password = params[:session][:username], params[:session][:password]
      
      self.current_user = User.authenticate(login, password)
      if logged_in?
        if params[:remember_me] == "1"
          self.current_user.remember_me
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        end
        successful_login(self.current_user)
      else
        failed_login('Invalid username or password')
      end
    end

    def open_id_authentication
      openid_url = params[:openid_url]
      
      if request.post?
        request = consumer.begin(openid_url)
        
        case request.status
        when OpenID::SUCCESS
          return_to = url_for(:action=> 'complete')
          trust_root = url_for(:controller=>'')
          
          url = request.redirect_url(trust_root, return_to)
          redirect_to(url)
          return
          
        when OpenID::FAILURE
          escaped_url = CGI::escape(openid_url)
          flash[:notice] = "Could not find OpenID server for #{escaped_url}"
        else
          flash[:notice] = "An unknown error occured."
        end
      end
    end

  private
  
    def successful_login(user)
      # update "last seen" attribute
      user.update_attribute(:last_seen_at, Time.now)
      respond_to do |format|
        flash[:notice] = "Logged in successfully. Welcome to myExperiment!"
        format.html { URI.parse(session[:return_to]).path == '/' ? redirect_to(user_path(user)) : redirect_back_or_default(user_path(user)) }
        format.xml { head :ok }
      end
    end

    def failed_login(message)
      respond_to do |format|
        flash.now[:error] = message
        format.html { render :action => 'new' }
        format.xml { head :forbidden }
      end
    end
    
  # Get the OpenID::Consumer object.
  def consumer
    # create the OpenID store for storing associations and nonces,
    # putting it in your app's db directory
    store_dir = Pathname.new(RAILS_ROOT).join('db').join('openid-store')
    store = OpenID::FilesystemStore.new(store_dir)

    return OpenID::Consumer.new(session, store)
  end
end
