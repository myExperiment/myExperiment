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
      when 'index'; doc = rest_index_request(rules, query)
      when 'crud';  doc = rest_crud_request(rules)
      when 'call';  doc = rest_call_request(rules, query)
      else;         bad_rest_request
    end

    sw = StringIO.new; doc.write(sw, 0); text = sw.string

    render :xml => text
  end
end

