# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_m2_session_id'
  
  before_filter :login_required
  
  def current_user
    @current_user ||= ((session[:user_id] && User.find(session[:user_id])) || 0)
  end
    
  def logged_in?
    current_user != 0
  end
  
  def login_required
    unless logged_in?
      session[:user_id] = 1
      #session[:return_to] = request.request_uri
      # replace with redirect to login page instead!
      #redirect_to session[:return_to]
    end
    
    true
  end
end
