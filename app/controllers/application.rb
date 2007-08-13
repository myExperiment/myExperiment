# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require_dependency "openid_login_system"

class ApplicationController < ActionController::Base
  include OpenidLoginSystem
  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_m2_session_id'
  
  def current_user
    @current_user ||= ((session[:user_id] && User.find(session[:user_id])) || 0)
  end
  
  def logged_in?
    current_user != 0
  end
  
private
  
  def authorize
    return true if logged_in?
    
    respond_to do |format|
      flash[:notice] = "You must be logged in to perform this action."
      format.html { redirect_to request.env["HTTP_REFERER"] || url_for(:controller => '') }
      format.xml { head :ok }
    end
      
    return false
  end
end
