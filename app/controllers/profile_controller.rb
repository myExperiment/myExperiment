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

class ProfileController < ApplicationController
  before_filter :login_required
  
  helper :people

  def index

    redirect_to :action => 'edit'

  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def edit
    @profile = @user.profile
  end

  def update
    @profile = @user.profile
    if @profile.update_attributes(params[:profile])
      flash[:notice] = 'Your profile has been updated'
      redirect_to :controller => :my, :action => :profile, :id => @user.id
    else
      render :action => 'edit'
    end
  end

  def workflows
    @person = User.find(params[:id])
    @workflows = Workflow.find(:all, :conditions => ["user_id = ?", params[:id]],
                               :page => {:size => 12, :current => params[:page], :first => 1})
  end

  def show
    @user = User.find(session[:user_id]);
    @person = User.find(params[:id])
    @profile = @person.profile

    @workflows = Workflow.find_all_by_user_id(@person.id, :order => 'created_at DESC', :limit => 3)
    @projects = Project.find_all_by_user_id(@person.id, :order => 'created_at DESC', :limit => 3)
    
    @friends = find_all_friends @person
  end

  def name
    @profile = @user.profile
  end
  
protected
  def find_all_friends(id=params[:id], of_mine=true, with_me=true)
    # create friends array
    friends = Array.new
      
    if of_mine
      # find 'my friends' (users who you are friends with)
      # id --friends_with--> user
      Friendship.find_all_by_user_id(id, :order => 'accepted_at DESC').each do |user|
        friends << user.friend_id
      end
    end
      
    if with_me
      # find 'friends of me' (users who have you as a friend)
      # friend --friends_with-->id
      Friendship.find_all_by_friend_id(id, :order => 'accepted_at DESC').each do |friend|
        friends << friend.user_id unless friends.include? friend.user_id
      end
    end
      
    return friends
  end
end
