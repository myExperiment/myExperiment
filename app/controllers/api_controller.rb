# myExperiment: app/controllers/api.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'rexml/document'
require 'base64'
require 'lib/rest'

class ApiController < ApplicationController

  before_filter :oauth_required

  def process_request

    # all responses from the API are in XML
    response.content_type = "application/xml"

    user = current_user

    auth = request.env["HTTP_AUTHORIZATION"]

    if auth and auth.starts_with?("Basic ")
      credentials = Base64.decode64(auth.sub(/^Basic /, '')).split(':')
      user = User.authenticate(credentials[0], credentials[1])

      return rest_error(401) if user.nil?

    end

    query  = CGIMethods.parse_query_parameters(request.query_string)
    method = request.method.to_s.upcase
    uri    = params[:uri]

    # logger.info "current token: #{current_token.inspect}"
    # logger.info "current user: #{user.id}"
    # logger.info "query: #{query}"
    # logger.info "method: #{method}"
    # logger.info "uri: #{uri}"

    return rest_error(400) if TABLES['REST'][:data][uri].nil? 
    return rest_error(400) if TABLES['REST'][:data][uri][method].nil?

    rules = TABLES['REST'][:data][uri][method]

    # key check - if an oauth access token is in use, this means that we must
    # only allow requests where explicit permission has been given

    if current_token
      requested_permission = "#{method} #{uri}"
      permission_found     = false

      current_token.client_application.permissions.each do |permission|
        permission_found = true if permission.for == requested_permission
      end

      return rest_error(403) if permission_found == false
    end  

    case rules['Type']
      when 'index'; doc = rest_index_request(rules, user, query)
      when 'crud';  doc = rest_crud_request(rules, user)
      when 'call';  doc = rest_call_request(rules, user, query)
      else;         return rest_error(400)
    end
  end
end

