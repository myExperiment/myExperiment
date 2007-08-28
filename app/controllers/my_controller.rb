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

class MyController < ApplicationController
  before_filter :login_required, :except => [:index, :about]

  before_filter :find_user, :except => [:index, :about]

  # find_xxx methods are listed at the bottom of this controller
  # each one is enacted using a call to before_filter..
  # to enable one for your action, simple add a reference
  before_filter :find_all_friends, :only => [ :profile, :contacts ] # @friends
  before_filter :find_forums_and_mods, :only => [ :forums ]         # @forums @moderatorships
  before_filter :find_workflows, :only => [ :profile, :workflows ]  # @workflows
  before_filter :find_projects, :only => [ :profile, :projects ]    # @projects
  before_filter :find_blogs, :only => [ :blog ]                     # @blogs

  helper :people

  def index
    if @user
      redirect_to :action => 'dashboard'
    else
      redirect_to :action => 'about'
    end
  end

  def profile
  end

  def contacts
    params[:page] ||= 0
    
    @friend_pages, @friends = paginate_collection @friends, :page => params[:page], :per_page => 6
  end

  def workflows
  end

  def projects
  end

  def forums
  end

  def blog
    @user_blogs = Blog.find(:all, :conditions => ["user_id = ?", @user])
    @blog_pages, @paginated_blogs = paginate_collection @user_blogs, :page => @params[:page]
  end

  def about
  end

  def dashboard
  end

protected
  def find_user
    if session[:user_id]
      @user = User.find(session[:user_id])
    end
  end

  def find_all_friends(id=@user, of_mine=true, with_me=true)
    # create friends array
    @friends = Array.new

    if of_mine
      # find 'my friends' (users who you are friends with)
      # id --friends_with--> user
      Friendship.find_all_by_user_id(id, :conditions => ["accepted_at < ?", Time.now], :order => 'accepted_at DESC').each do |user|
        @friends << user.friend_id
      end
    end

    if with_me
      # find 'friends of me' (users who have you as a friend)
      # friend --friends_with-->id
      Friendship.find_all_by_friend_id(id, :conditions => ["accepted_at < ?", Time.now], :order => 'accepted_at DESC').each do |friend|
        @friends << friend.user_id unless @friends.include? friend.user_id
      end
    end

    return @friends
  end

  def find_forums_and_mods(id=@user)
    @forums = Forum.find_all_by_owner_id(@user.id, :order => 'name ASC')
    @moderatorships = Moderatorship.find_all_by_user_id(@user.id)
  end

  def find_workflows(id=@user)
    # @workflows = Workflow.find_all_by_user_id(@user.id, :order => 'created_at DESC', :limit => 3)
    
    @workflows = Workflow.find(:all, :conditions => ["user_id = ?", session[:user_id]],
                               :order => "created_at DESC",
                               :page => {:size => 18, :current => params[:page], :first => 1})
                               
    @shared_users = SharingUser.find_all_by_user_id(@user.id)
  end

  def find_projects(id=@user)
    @projects = []
    Membership.find_all_by_user_id(@user.id, :order => 'project_id ASC').each do |m|
      @projects << Project.find(m.project_id)
    end
    
    # @projects = Project.find_all_by_user_id(@user.id, :order => 'created_at DESC', :limit => 3)
  end

  def find_blogs(id=@user)
    @blogs = Blog.find_all_by_user_id(@user.id, :order => 'created_at DESC')
  end
end
