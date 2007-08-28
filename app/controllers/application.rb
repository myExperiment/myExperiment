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
  
  include SavageBeast::AuthenticationSystem

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
    (@membership = Membership.find_by_project_id_and_user_id(project,user)) ? true : false
  end
      
  def record_in_history(params)
    record = History.new
    
    record.user_id = current_user.id.to_i if session[:user_id]
    record.execution_time = Time.now
    record.action = params[:action].to_s
    record.controller = params[:controller].to_s
    record.params_id = params[:id].to_i
    
    record.save!
  end
  
  # returns an array of nested [count, id] pairs (in descending order)
  def query_history!(controller, action, user_id=nil)
    cond = (user_id and (user_id.to_i > 0)) ? [ "action = ? and controller = ? and user_id = ?", action, controller, user_id.to_s ] : [ "action = ? and controller = ?", action, controller ]
    
    hash = {}
    History.find(:all, :conditions => cond).each do |h|
      if hash.has_key? h.params_id
        hash[h.params_id] = hash[h.params_id].to_i + 1
      else
        hash[h.params_id] = 1
      end
    end
    
    array = []
    hash.each do |key, value|
      array << [ value, key ]
    end
    
    return array.sort.reverse
  end
  
  # returns the cached result of query_history!
  # caches the result if the previous entry is more than 3 hours old
  def query_history(controller, action)
    # if cached result already exists
    if (cached = CachedHistory.find_by_controller_and_action(controller, action))
      # if result is less than 3 hours old
      if cached.updated_at > (Time.now - 3.hours)
        # return cached result
        return cached_history_to_a(cached.result), cached.updated_at
      else
        # calculate new result
        result = query_history!(controller, action)
        
        cached.updated_at = Time.now
        cached.result = cached_history_to_s(result)
        
        # return result
        if cached.save
          return result, cached.updated_at
        end
      end
    else
      # calculate new result
      result = query_history!(controller, action)
      
      # create new cached record
      record = CachedHistory.new
      record.action, record.controller, record.updated_at = action, controller, Time.now
      record.result = cached_history_to_s(result)
        
      # return result
      if record.save
        return result, record.updated_at
      end
    end
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
  
private

  def cached_history_to_s(array)
    string = String.new
    
    array.each do |pair|
      string << "," unless string.empty?
      
      string << "#{pair[0]}-#{pair[1]}"
    end
    
    return string
  end
  
  def cached_history_to_a(string)
    array = []
    
    string.split(",").each do |pair|
      split_up = pair.split("-")
      
      array << [split_up[0], split_up[1]]
    end
    
    return array
  end
      
end
