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

require "pathname"
require "cgi"

# load the openid library
begin
  require "rubygems"
  require_gem "ruby-openid", ">= 1.0.2"
rescue LoadError
  require "openid"
end

class AuthController < ApplicationController
  layout  'login'

  def index
    redirect_to :action => 'login'
  end

  # process the login request, disover the openid server, and
  # then redirect.
  def login
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
        flash[:notice] = "Couldn't find your OpenID server - please check and try again"

      else
        flash[:notice] = "An unknown error occured. Please try again."

      end
    end

  end

  # handle the openid server response
  def complete
    response = consumer.complete(params)

    case response.status
    when OpenID::SUCCESS

      @user = User.get(response.identity_url)

      # create user object if one does not exist
      if @user.nil?
        @user = User.new(:openid_url => response.identity_url)
        @user.save
        Profile.create(:user_id => @user.id)
        avatar = Picture.create(:user_id => @user.id, :data => StringIO.new(File.new('public/images/avatar.png').read))
        @user.update_attribute(:avatar, avatar.id)
      end

      # storing both the openid_url and user id in the session for for quick
      # access to both bits of information.  Change as needed.
      session[:user_id] = @user.id

      flash[:notice] = "Logged in as #{response.identity_url}"

      redirect_to_stored
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

    redirect_to :action => 'login'
  end

  def logout
    session[:user_id] = nil
  end

    def update
    @profile = @user.profile
    @profile.update_attributes(params[:profile])
    redirect_to :controller => 'my'
  end


  def welcome
  end

  private

  # Get the OpenID::Consumer object.
  def consumer
    # create the OpenID store for storing associations and nonces,
    # putting it in your app's db directory
    store_dir = Pathname.new(RAILS_ROOT).join('db').join('openid-store')
    store = OpenID::FilesystemStore.new(store_dir)

    return OpenID::Consumer.new(session, store)
  end

  # get the logged in user object
  def find_user
    return nil if session[:user_id].nil?
    User.find(session[:user_id])
  end

  def name

    if session[:user_id]
      redirect_to :controller => 'my', :action => 'dashboard'
    end

  end


end
