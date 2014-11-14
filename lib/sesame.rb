# myExperiment: lib/sesame.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'net/http/persistent'

module Sesame
  class Repository

    VALID_CONTENT_TYPES = ['application/rdf+xml', 'text/plain', 'application/x-turtle', 'text/rdf+n3', 'application/trix',
      'application/x-trig', 'application/x-binary-rdf'].freeze

    def initialize(repo_url, name = 'sesame_connection')
      @url = repo_url # http://example.com:8080/openrdf-sesame/repositories/my_repo
      @connection = Net::HTTP::Persistent.new name
    end

    def insert(rdf, context, content_type = 'application/x-turtle')
      raise "Content type not supported: #{content_type}" unless VALID_CONTENT_TYPES.include?(content_type)

      url = URI("#{@url}/statements?context=#{CGI.escape(context)}")
      request = Net::HTTP::Put.new url.request_uri
      request.body = rdf
      request.content_type = content_type

      begin
        response = @connection.request url, request   #Net::HTTP::Persistent::Error if can't connect
      rescue Net::HTTP::Persistent::Error
        raise ConnectionException.new, "Couldn't connect to #@url"
      end

      case response.code
        when '204'
          true
        else
          raise RequestException.new(response.code, response.body)
      end
    end

    alias_method :update, :insert

    def query(query)
      url = URI("#{@url}?query=#{CGI.escape(query)}")
      request =  Net::HTTP::Get.new url.request_uri
      request['accept'] = 'application/sparql-results+xml'
      begin
        response = @connection.request url, request
      rescue Net::HTTP::Persistent::Error
        raise ConnectionException.new, "Couldn't connect to #@url"
      end

      case response.code
        when '200'
          SPARQLResults.from_xml(response.body)
        when '400'
          raise QueryException.new(response.code, response.body)
        else
          raise RequestException.new(response.code, response.body)
      end
    end

    ##
    # Valid options for parameters:
    # :context, :subject, :object, :predicate
    #
    # Needs at least one of the above
    def delete(parameters = {})
      unless parameters.keys.any? {|k| [:subject, :predicate, :object, :context].include?(k)}
        raise "At least one of :subject, :predicate, :object,  or :context required"
      end

      url = URI("#{@url}/statements?#{parameters.to_query}")
      request = Net::HTTP::Delete.new url.request_uri
      begin
        response = @connection.request url, request
      rescue Net::HTTP::Persistent::Error
        raise ConnectionException.new, "Couldn't connect to #@url"
      end

      case response.code
        when '204'
          true
        else
          raise RequestException.new(response.code, response.body)
      end
    end

  end

  class ConnectionException < Exception;  end

  class RequestException < Exception
    attr_reader :code

    def initialize(code, message)
      super(message)
      @code = code
    end

  end

  class QueryException < RequestException;  end
end
