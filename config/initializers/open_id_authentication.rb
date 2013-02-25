require 'open_id_authentication'
ActionController::Base.send :include, OpenIdAuthentication::ControllerMethods
