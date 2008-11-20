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

    query  = CGIMethods.parse_query_parameters(request.query_string)
    method = request.method.to_s.upcase
    uri    = params[:uri]

   # logger.info "current token: #{current_token.inspect}"
   # logger.info "current user: #{current_user.id}"
   # logger.info "query: #{query}"
   # logger.info "method: #{method}"
   # logger.info "uri: #{uri}"

    return bad_rest_request if TABLES['REST'][:data][uri].nil? 
    return bad_rest_request if TABLES['REST'][:data][uri][method].nil?

    rules = TABLES['REST'][:data][uri][method]

    # key check - if an oauth access token is in use, this means that we must
    # only allow requests where explicit permission has been given

    if current_token
      requested_permission = "#{method} #{uri}"
      permission_found     = false

      current_token.client_application.permissions.each do |permission|
        permission_found = true if permission.for == requested_permission
      end

      if permission_found == false
        render :xml => rest_error_response(403, 'Not authorized').to_s
        return
      end
    end  

    case rules['Type']
      when 'index'; doc = rest_index_request(rules, query)
      when 'crud';  doc = rest_crud_request(rules)
      when 'call';  doc = rest_call_request(rules, query)
      else;         bad_rest_request
    end

    current_user = nil
    current_token = nil
    render :xml => doc.to_s
  end
end

