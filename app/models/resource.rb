require 'securerandom'

class Resource < ActiveRecord::Base

  include ResearchObjectsHelper

  belongs_to :research_object

  belongs_to :content_blob, :dependent => :destroy

  belongs_to :proxy_for,          :primary_key => :path, :foreign_key => :proxy_for_path,     :class_name => 'Resource'
  has_one    :proxy,              :primary_key => :path, :foreign_key => :proxy_for_path,     :class_name => 'Resource'

  belongs_to :proxy_in,           :primary_key => :path, :foreign_key => :proxy_in_path,      :class_name => 'Resource'
  has_many   :proxies,            :primary_key => :path, :foreign_key => :proxy_in_path,      :class_name => 'Resource'

  belongs_to :aggregated_by,      :primary_key => :path, :foreign_key => :aggregated_by_path, :class_name => 'Resource'
  has_many   :aggregates,         :primary_key => :path, :foreign_key => :aggregated_by_path, :class_name => 'Resource'

  belongs_to :ao_body,            :primary_key => :path, :foreign_key => :ao_body_path,       :class_name => 'Resource'
  has_one    :ao_stub,            :primary_key => :path, :foreign_key => :ao_body_path,       :class_name => 'Resource'

  belongs_to :resource_map,       :primary_key => :path, :foreign_key => :resource_map_path,  :class_name => 'Resource'
  has_one    :is_resource_map_to, :primary_key => :path, :foreign_key => :resource_map_path,  :class_name => 'Resource'

  has_many :annotation_resources, :foreign_key => 'annotation_id', :dependent => :destroy

  validates_uniqueness_of :path, :scope => :research_object_id
  validates_presence_of :content_type
  validates_presence_of :path
  validates_presence_of :content_blob

  def is_manifest?
    path == ResearchObject::MANIFEST_PATH
  end

  def description

    graph = RDF::Graph.new

    ro_uri = RDF::URI(research_object.uri)
    uri    = resource_uri

    if is_manifest?
      graph << [uri, RDF.type, RDF::URI("http://purl.org/wf4ever/ro#Manifest")]
      graph << [uri, RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/ResourceMap")]
      graph << [uri, RDF::URI("http://www.openarchives.org/ore/terms/describes"), ro_uri]
    end

    if is_resource
      graph << [uri, RDF.type, RDF::URI("http://purl.org/wf4ever/ro#Resource")]
    end

    if is_aggregated
      graph << [uri, RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/AggregatedResource")]
    end

    if is_proxy
      graph << [uri, RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/Proxy")]
      graph << [uri, RDF::URI("http://www.openarchives.org/ore/terms/proxyIn"), ro_uri.join(proxy_in_path)]
      graph << [uri, RDF::URI("http://www.openarchives.org/ore/terms/proxyFor"), ro_uri.join(proxy_for_path)]
    end

    if is_annotation
      graph << [uri, RDF.type, RDF::URI("http://purl.org/wf4ever/ro#AggregatedAnnotation")]
      graph << [uri, RDF.type, RDF::URI("http://purl.org/ao/Annotation")]
      graph << [uri, RDF::URI("http://purl.org/ao/body"), ro_uri.join(ao_body_path)]

      annotation_resources.each do |resource|
        graph << [uri, RDF::URI("http://purl.org/wf4ever/ro#annotatesAggregatedResource"), ro_uri.join(resource.resource_path)]
      end
    end

    if is_resource_map

      folder = is_resource_map_to

      folder_uri = RDF::URI(folder.uri)

      graph << [uri, RDF.type, ORE.ResourceMap]
      graph << [uri, ORE.describes, folder_uri]

      graph << [folder_uri, RDF.type, RO.folder]
      graph << [folder_uri, RDF.type, ORE.Aggregation]
      graph << [folder_uri, ORE.isDescribedBy, uri]
      graph << [folder_uri, RDF::DC.created, folder.created_at.to_datetime]
      graph << [folder_uri, RDF::DC.creator, RDF::URI(folder.creator_uri)]
      graph << [folder_uri, ORE.isAggregatedBy, RDF::URI(folder.aggregated_by.uri)] if folder.aggregated_by_path

      folder.aggregates.each do |aggregate|
        graph << [folder_uri, ORE.aggregates, RDF::URI(aggregate.uri)]
        graph << [RDF::URI(aggregate.uri), ORE.isAggregatedBy, folder_uri]
      end
    end

    if is_folder
      graph << [uri, RDF.type, RDF::URI("http://purl.org/wf4ever/ro#Resource")]
      graph << [uri, RDF.type, RDF::URI("http://purl.org/wf4ever/ro#Folder")]
      graph << [uri, RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/AggregatedResource")]
      graph << [uri, RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/Aggregation")]

      resource_map = Resource.find(:first, :conditions => { :path => resource_map_path })

      graph << [uri, RDF::URI("http://www.openarchives.org/ore/terms/isDescribedBy"), ro_uri.join(resource_map_path)]
    end

    graph << [uri, RDF::DC.created, created_at.to_datetime]
    graph << [uri, RDF::DC.creator, RDF::URI(creator_uri)] if creator_uri
    graph << [uri, RDF::URI("http://purl.org/wf4ever/ro#name"), name] if name

    if content_blob && !is_manifest?
      graph << [uri, RDF::URI("http://purl.org/wf4ever/ro#filesize"), content_blob.size]
      graph << [uri, RDF::URI("http://purl.org/wf4ever/ro#checksum"), RDF::URI("urn:MD5:#{content_blob.md5}")]
    end

    graph
  end

  def resource_uri
    RDF::URI(research_object.uri) + path
  end

  def uri
    RDF::URI(research_object.uri) + path
  end

  def generate_proxy(proxy_path = ".ro/proxies/#{SecureRandom.uuid}")

    ro_uri    = RDF::URI(research_object.uri)
    proxy_uri = RDF::URI(research_object.uri) + proxy_path

    graph = RDF::Graph.new
    graph << [proxy_uri, RDF.type,     ORE.Proxy]
    graph << [proxy_uri, ORE.proxyIn,  ro_uri]
    graph << [proxy_uri, ORE.proxyFor, resource_uri]

    graph
  end

  def update_graph!

    new_description = create_rdf_xml { |graph| graph << description }

    content_blob.destroy if content_blob
    content_blob = ContentBlob.new(:data => new_description)
    content_blob.save
  end
end
