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
    unless logged_in?
      flash[:notice] = "You are not logged in! (fix this in ApplicationController.rb)"
      
      respond_to do |format|
        format.html { redirect_to :controller => 'users' }
        format.xml { head :ok }
      end
    end
  end
end
