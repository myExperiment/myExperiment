# myExperiment: app/models/research_object.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'lib/acts_as_site_entity'
require 'lib/acts_as_contributable'

require 'curl'
require 'xml/libxml'
require 'zip/zip'
require 'rdf'
require 'rdf/raptor'
require 'wf4ever/rosrs_client'

class ResearchObject < ActiveRecord::Base

  acts_as_site_entity
  acts_as_contributable

  has_many :statements, :dependent => :destroy

  belongs_to :content_blob, :dependent => :destroy

  validates_presence_of :title
  validates_presence_of :content_blob

  format_attribute :description

  attr_accessor :manifest

  def load_graph_from_zip

    begin

      filename = "tmp/ro.#{Process.pid}.zip"

      File.open(filename, "w") do |f|
        f.write(content_blob.data)
      end

      zip = Zip::ZipFile.open(filename)

      metadata = zip.read(".ro/manifest.rdf")

      # close files

      zip.close
      FileUtils.rm_rf(filename)

      # create RDF graph

      manifest_name = "tmp/manifest.#{Process.pid}.rdf"

      File.open(manifest_name, "w") do |f|
        f.write(metadata)
      end

      graph = RDF::Graph.load(manifest_name)

      FileUtils.rm_rf(manifest_name)

      # create triples

      graph.query([nil, nil, nil]).each do |s, p, o|

        statements.create(
            :subject_text =>   s.to_s,
            :predicate_text => p.to_s,
            :objekt_text =>    o.to_s)
      end

      graph
    end
  end

  def load_graph

    # create RDF graph

    manifest_name = "tmp/graph.#{Process.pid}.rdf"

    File.open(manifest_name, "w") do |f|
      f.write(content_blob.data)
    end

    graph = RDF::Graph.load(manifest_name)

    FileUtils.rm_rf(manifest_name)

    # create triples

    graph.query([nil, nil, nil]).each do |s, p, o|

      statements.create(
          :subject_text   => s.to_s,
          :predicate_text => p.to_s,
          :objekt_text    => o.to_s,
          :context_uri    => url)
    end

    graph
  end

  def wf4ever_resources

    resources = statements.find(:all, :conditions =>
      ['predicate_text = ? AND objekt_text = ?',
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
        'http://purl.org/wf4ever/ro#Resource']).map do
      |a| a.subject_text
    end

    resources.map do |resource|

      metadata = {}

      statements.find(:all, :conditions =>
        ['subject_text = ?', resource]).each do |statement|

        case statement.predicate_text
        when "http://purl.org/wf4ever/ro#name":      metadata[:name]    = statement.objekt_text
        when "http://purl.org/dc/terms/created":     metadata[:created] = Date.parse(statement.objekt_text)
        when "http://purl.org/dc/terms/creator":     metadata[:creator] = statement.objekt_text
        when "http://purl.org/wf4ever/ro#checksum" : metadata[:md5]     = statement.objekt_text
        when "http://purl.org/wf4ever/ro#filesize" : metadata[:size]    = statement.objekt_text.to_i
        end

      end

      metadata

    end

  end

  def self.related_research_objects_to_t2(uuid)

    self.related_research_objects("

      PREFIX ro: <http://purl.org/wf4ever/ro#>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>

      SELECT ?resource ?creator ?created
      WHERE {
         ?resource a ro:ResearchObject ;
           dcterms:created ?created ;
             dcterms:creator ?creator .
      }
      ORDER BY DESC(?created)

      LIMIT 10")

  end

  def self.related_research_objects(query)

    Conf.research_object_endpoints.each do |endpoint|

      begin

        url = "#{endpoint}?query=#{CGI::escape(query)}"

        curl = Curl::Easy.http_get(url)

        if curl.response_code == 200

          ns  = { :s => 'http://www.w3.org/2005/sparql-results#' }

          doc = LibXML::XML::Parser.string(curl.body_str).parse
          
          doc.root.find('/s:sparql/s:results/s:result/s:binding[@name="resource"]/s:uri', ns).each do |uri|
            puts uri.content
          end

          return curl.body_str
        end
        
      end
    end
  end

  def annotations

    results = []

    annotation_bodies = statements.find(:all,
        :conditions => ['predicate_text = ?', 'http://purl.org/ao/body'])

    annotation_bodies.each do |body|

      type = statements.find(:first,
          :conditions => ['predicate_text = ? AND subject_text = ?',
          'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
          body.subject_text])

      next if type.nil?

      results << { :type => type.objekt_text, :body => body.objekt_text }
    end

    results
  end

  def create_annotation_body(resource_uri, body, namespaces)

    namespaces["rdf"] = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

    doc = LibXML::XML::Document.new
    doc.root = LibXML::XML::Node.new("rdf:RDF")
    doc.root["xml:base"] = url

    namespaces.each do |name, uri|
      doc.root["xmlns:#{name}"] = uri
    end

    description = LibXML::XML::Node.new("rdf:Description")
    description["rdf:about"] = resource_uri
    description << body
    doc.root << description

    doc
  end

  def set_simple_annotation(resource_uri, predicate, namespaces, term, new_value)

    session = ROSRS::Session.new(url, Conf.rodl_bearer_token)

    # Remove existing annotations of the same structure

    annotations = session.get_annotation_graphs(url, resource_uri)

    annotations.each do |annotation|

      next unless annotation[:body].count == 1
      next unless annotation[:body].query(:predicate => predicate).count == 1

      c, r, h, d = session.do_request("DELETE", annotation[:stub], {} )
      c, r, h, d = session.do_request("DELETE", annotation[:body_uri], {} )
    end

    # Create the new annotation

    annotation_body = create_annotation_body(resource_uri,
        LibXML::XML::Node.new(term, new_value),
        namespaces)

    agraph = RDFGraph.new(:data => annotation_body.to_s, :format => :xml)

    code, reason, stub_uri, body_uri = session.create_internal_annotation(url, resource_uri, agraph)
  end

  def set_dc_title(resource_uri, value)
    set_simple_annotation(resource_uri,
        RDF::DC.title,
        { "dct" => "http://purl.org/dc/terms/" },
        "dct:title",
        value)
  end

  def set_dc_description(resource_uri, value)
    set_simple_annotation(resource_uri,
        RDF::DC.description,
        { "dct" => "http://purl.org/dc/terms/" },
        "dct:description",
        value)
  end

  def manifest

    return @manifest if @manifest

    session = ROSRS::Session.new(url, Conf.rodl_bearer_token)

    manifest_uri, manifest = session.get_manifest(url)

    @manifest = manifest
  end

  def resolve_resource_uri(resource_uri)
    RDF::URI.parse(url).join(RDF::URI.parse(resource_uri))
  end

  def aggregated_resources
    manifest.query([nil, RDF.type, RDF::RO.Resource]).map do |statement|
      statement.subject
    end
  end
end

