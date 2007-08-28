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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_myexperiment_session_id'

  before_filter :profile_setup, :user_agent_check

  require_dependency 'openid_login_system'

 include OpenidLoginSystem

  def profile_setup

     if session[:user_id]
        @user = User.find(session[:user_id])
        if @user.profile.name.blank? and not self.kind_of? AuthController
        redirect_to(:controller => 'auth', :action => 'name')
        end
     end

    if session[:user_id] and self.kind_of? MyController

    end

  end

  def user_agent_check

    user_agent = request.user_agent.downcase
    @is_search_bot = false
    @is_mobile_device = false
    @is_apple_iphone = false
    @is_rubbish_browser = false

    ['msnbot', 'yahoo! slurp','googlebot'].each { |b|
      @is_search_bot = true if user_agent.include? b
    }

    ['iphone', 'symbianos', 'iemobile'].each { |b|
      @is_mobile_device = true if user_agent.include? b
    }

    ['iphone'].each { |b|
      @is_apple_iphone = true if user_agent.include? b
    }

    ['msie 5', 'msie 4', 'msie 3'].each { |b|
      @is_rubbish_browser = true if user_agent.include? b
    }

  end

 def login_required
  if session[:user_id]
   return true
  end
  flash[:warning]='Please login to continue'
  session[:return_to]=request.request_uri
  redirect_to :controller => 'auth', :action => 'login'
  return false
 end

 def redirect_to_stored
  if return_to = session[:return_to]
   session[:return_to]=nil
   redirect_to_url(return_to)
  else
   redirect_to :controller=>'my'
  end
 end

 # paginate_collection is from http://snippets.dzone.com/posts/show/13

 def paginate_collection(collection, options = {})
  default_options = {:per_page => 10, :page => 1}
  options = default_options.merge options

  pages = Paginator.new self, collection.size, options[:per_page], options[:page]
  first = pages.current.offset
  last = [first + options[:per_page], collection.size].min
  slice = collection[first...last]
  return [pages, slice]
 end

 # Tests to see if the user is a member of the project
 def user_on_project(user,project)
        @membership = Membership.find_by_project_id_and_user_id(project,user)
        return true if (@membership)
        return false
 end

 # Functions for BlueCloth Markdown

 def make_big_title(title)
    underline="\n"
        title.length.times{underline << "="}
        title << underline+"\n"
        return title
 end

 def make_small_title(title)
        underline="\n"
        title.length.times{underline << "-"}
        title << underline+"\n"
        return title
  end
end
