# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_m2_session_id'
  
  def current_user=(value)
    if (@current_user = value)
      session[:user_id] = current_user.id
    end
  end

  def current_user
    @current_user ||= ((session[:user_id] && User.find(session[:user_id])) || 0)
  end
    
  def logged_in?
    current_user != 0
  end
  
  def login_required
    if session[:user_id]
      true
    else
      #flash[:notice] = "Please login to continue"
      #session[:return_to] = request.request_uri
      # replace with redirect to login page
      
      session[:user_id] = 1
      
      false
    end
  end
end
