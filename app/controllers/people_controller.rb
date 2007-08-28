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

class PeopleController < ApplicationController

  before_filter :login_required

  require 'contacts'
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :remove_friend, :add_friend ],
  :redirect_to => { :action => :list }

  def index
    redirect_to :action => 'list'
  end

  def list
    #friends = @user.pending_or_accepted_friends
    #@collection = User.find(:all, :conditions => [ "id IN (?)", friends], :page => {:size => 12, :current => params[:page], :first => 1})
    
    @collection = User.find(:all, :order => "created_at DESC", :page => { :size => 9, :current => params[:page], :first => 1})
  end

  def add_friend
    @user = User.find(session[:user_id]);
    @friend = User.find(params[:id])
    @user.request_friendship_with @friend

    #this should go somewhere else?
    @message = Message.new()
    @message.from_id = @user.id
    @message.to_id = @friend.id
    @message.subject = 'You have a new friend request'
    @message.body = render_to_string :action => 'friend_template', :layout => false
    @message.save

    redirect_to :action => 'list'
  end

  def remove_friend
    friend = User.find(params[:id])
    @user.destroy_friendship_with(friend)

    redirect_to :action => 'list'
  end

  def accept_friend
    @user = User.find(session[:user_id]);
    friend = User.find(params[:id])
    if @user.pending_friends_for_me.include? friend
      @user.accept_friendship_with(friend)
    end

    redirect_to :action => 'list'
  end

  def decline_friend
    @user = User.find(session[:user_id]);
    friend = User.find(params[:id])
    if @user.pending_friends_for_me.include? friend
      @user.destroy_friendship_with(friend)
    end

    redirect_to :action => 'list'
  end

  def search
    unless params[:query].blank?
      @query = params[:query]
      #params[:searchtext] = sanitize(params[:searchtext])
      params[:page] = 1 unless params[:page]
      @collection = Profile.ferret_find(@query, :page => {:size => 9, :current => params[:page], :first => 1})
      render :action => 'results'
    else
      @collection = Profile.find(:all, :page => {:size => 9, :current => params[:page], :first => 1})
      render :action => 'results'
    end
  end

  def importer

    @provider = params[:id]
    @login = params[:name]
    @password = params[:password]

    @contacts = Contacts.new(@provider, @login, @password).contacts

  end


end
