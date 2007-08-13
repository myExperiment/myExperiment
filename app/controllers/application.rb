# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
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
    logout = false
    
    if logged_in?
      if session[:login_time] < (Time.now - 2.hours)
        if Auth.find(:first, :conditions => ["user_id = ?", current_user.id])
          logout = true
        else
          session[:user_id] = nil
          session.delete(:login_time)
        end
      else
        return true
      end
    end
    
    respond_to do |format|
      if logout == true
        redirect_to :controller => 'auth', :action => 'logout', :id => current_user.id
      else
        flash[:notice] = "You must be logged in to perform this action."
        format.html { redirect_to request.env["HTTP_REFERER"] || url_for(:controller => '') }
        format.xml { head :ok }
      end
    end
      
    return false
  end
end
