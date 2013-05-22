# myExperiment: lib/sparql_results.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'libxml'

class SPARQLResults

  include Enumerable

  attr_reader :variables

  def self.from_xml(xml)
    doc = LibXML::XML::Parser.string(xml).parse
    root = doc.root
    root.namespaces.default_prefix = "ns"

    variables = []
    root.find('ns:head/ns:variable').each do |variable_node|
      variables << variable_node['name'].to_sym
    end

    results = []
    root.find('ns:results/ns:result').each do |result_node|
      result = {}
      result_node.find('ns:binding').each do |binding_node|
        content_node = binding_node.find_first('*')
        case content_node.name
          when 'uri'
            content = URI(content_node.content)
          else
            content = content_node.content
        end
        result[binding_node['name'].to_sym] = content
      end
      results << result
    end

    SPARQLResults.new(variables, results)
  end

  def initialize(variables, results)
    @variables = variables
    @results = results
  end

  def each(&block)
    @results.each(&block)
  end

  def size
    @results.size
  end

end