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

class ResearchObject < ActiveRecord::Base

  acts_as_site_entity
  acts_as_contributable

  has_many :annotations, :dependent => :destroy

  belongs_to :content_blob, :dependent => :destroy

  validates_presence_of :title
  validates_presence_of :content_blob

  format_attribute :description

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

        annotations.create(
            :subject_text =>   s.to_s,
            :predicate_text => p.to_s,
            :objekt_text =>    o.to_s)
      end

      graph
    end
  end

  def load_graph

    # create RDF graph

    manifest_name = "tmp/graph.#{Process.pid}.ttl"

    File.open(manifest_name, "w") do |f|
      f.write(content_blob.data)
    end

    graph = RDF::Graph.load(manifest_name)

    FileUtils.rm_rf(manifest_name)

    # create triples

    graph.query([nil, nil, nil]).each do |s, p, o|

      annotations.create(
          :subject_text =>   s.to_s,
          :predicate_text => p.to_s,
          :objekt_text =>    o.to_s)
    end

    graph
  end

  def wf4ever_resources

    resources = annotations.find(:all, :conditions =>
      ['predicate_text = ? AND objekt_text = ?',
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
        'http://purl.org/wf4ever/ro#Resource']).map do
      |a| a.subject_text
    end

    resources.map do |resource|

      metadata = {}

      annotations.find(:all, :conditions =>
        ['subject_text = ?', resource]).each do |annotation|

        case annotation.predicate_text
        when "http://purl.org/wf4ever/ro#name":      metadata[:name]    = annotation.objekt_text
        when "http://purl.org/dc/terms/created":     metadata[:created] = Date.parse(annotation.objekt_text)
        when "http://purl.org/dc/terms/creator":     metadata[:creator] = annotation.objekt_text
        when "http://purl.org/wf4ever/ro#checksum" : metadata[:md5]     = annotation.objekt_text
        when "http://purl.org/wf4ever/ro#filesize" : metadata[:size]    = annotation.objekt_text.to_i
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

  def ao_annotations

    results = []

    annotation_bodies = annotations.find(:all,
        :conditions => ['predicate_text = ?', 'http://purl.org/ao/body'])

    annotation_bodies.each do |body|

      type = annotations.find(:first,
          :conditions => ['predicate_text = ? AND subject_text = ?',
          'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
          body.subject_text])

      next if type.nil?

      results << { :type => type.objekt_text, :body => body.objekt_text }
    end

    results
  end

end

