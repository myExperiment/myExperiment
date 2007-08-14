# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require_dependency "openid_login_system"

class ApplicationController < ActionController::Base
  include OpenidLoginSystem
  
  include AuthenticatedSystem # include in application.rb
  before_filter :login_from_cookie
  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_m2_session_id'
end
