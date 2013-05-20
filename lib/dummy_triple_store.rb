# myExperiment: lib/dummy_triple_store.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

# For test purposes

require 'uri'

module DummyTripleStore
  class Repository

    attr_accessor :repo

    def initialize
      @repo = {}
    end

    def insert(rdf, context, content_type = 'application/x-turtle')
      @repo[context] = rdf
    end

    alias_method :update, :insert

    def query(query)
      @repo.keys.map {|key| {:workflow_uri => URI(key[1..-2])}}
    end

    def delete(parameters = {})
      @repo.delete(parameters[:context])
    end
  end
end
