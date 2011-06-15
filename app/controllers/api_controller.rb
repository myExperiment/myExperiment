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

      return rest_response(401, :reason => "Failed to authenticate") if user.nil?

    end

    method = request.method.to_s.upcase
    uri    = params[:uri]

    # logger.info "current token: #{current_token.inspect}"
    # logger.info "current user: #{user.id}"
    # logger.info "method: #{method}"
    # logger.info "uri: #{uri}"

    return rest_response(400) if TABLES['REST'][:data][uri].nil? 
    return rest_response(400) if TABLES['REST'][:data][uri][method].nil?

    rules = TABLES['REST'][:data][uri][method]

    # validate id and version query options

    case rules['Allow id']
      when 'required'
        return rest_response(400, :reason => "Must specify an id") if request.query_parameters['id'].nil?
      when 'no'
        return rest_response(400, :reason => "Cannot specify an id") if request.query_parameters['id']
    end

    case rules['Allow version']
      when 'required'
        return rest_response(400, :reason => "Must specify a version") if request.query_parameters['version'].nil?
      when 'no'
        return rest_response(400, :reason => "Cannot specify a version") if request.query_parameters['version']
    end

    # key check - if an oauth access token is in use, this means that we must
    # only allow requests where explicit permission has been given

    if current_token
      requested_permission = "#{method} #{uri}"
      permission_found     = false

      current_token.client_application.permissions.each do |permission|
        permission_found = true if permission.for == requested_permission
      end

      return rest_response(403, :reason => "OAuth token does not grant sufficient permission for this action") if permission_found == false
    end  

    case rules['Type']
      when 'index'; doc = rest_index_request(params[:uri], params[:format], rules, user, request.query_parameters)
      when 'crud';  doc = rest_crud_request(params[:uri], params[:format], rules, user, request.query_parameters)
      when 'call';  doc = rest_call_request(params[:uri], params[:format], rules, user, request.query_parameters)
      else;         return rest_response(500, :reason => "Unknown REST table type")
    end
  end
end

