# myExperiment: app/controllers/api.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'rexml/document'
require 'base64'
require 'lib/rest'

class ApiController < ApplicationController

  def process_request

    query  = CGIMethods.parse_query_parameters(request.query_string)
    method = request.method.to_s.upcase
    uri    = params[:uri]

    return bad_rest_request if TABLES['REST'][:data][uri].nil?
    return bad_rest_request if TABLES['REST'][:data][uri][method].nil?

    rules = TABLES['REST'][:data][uri][method]

    case rules['Type']
      when 'index'; render :xml => rest_index_request(rules, query).to_s
      when 'crud';  render :xml => rest_crud_request(rules)
      when 'call';  render :xml => rest_call_request(rules, query).to_s
      else;         bad_rest_request
    end
  end
end

