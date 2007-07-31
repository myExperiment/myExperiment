# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # current_user=, current_user and logged_in? are also found in application.rb (ApplicationController)

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
end
