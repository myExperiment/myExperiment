require 'rubygems'
require 'active_support'
require 'action_controller/request'
require 'rack/auth/abstract/request.rb'
require 'oauth/request_proxy/base'
require 'uri'

module OAuth::RequestProxy
  class ActionControllerRequest < OAuth::RequestProxy::Base
    proxies ActionController::AbstractRequest

    def method
      request.method.to_s.upcase
    end

    def uri
      uri = URI.parse(request.protocol + request.host + request.port_string + request.path)
      uri.query = nil
      uri.to_s
    end

    def parameters
      if options[:clobber_request]
        options[:parameters] || {}
      else
        params = request_params.merge(query_params).merge(header_params)
        params.stringify_keys! if params.respond_to?(:stringify_keys!)
        params.merge(options[:parameters] || {})
      end
    end

    protected

    def query_params
      request.query_parameters
    end

    def request_params
      request.request_parameters
    end

  end
end
