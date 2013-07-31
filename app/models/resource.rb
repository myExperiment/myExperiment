# myExperiment: app/models/resource.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require 'securerandom'

class Resource < ActiveRecord::Base

  include ResearchObjectsHelper

  before_save :copy_metadata

  belongs_to :research_object

  belongs_to :content_blob, :dependent => :destroy

  belongs_to :proxy_for,          :primary_key => :path, :foreign_key => :proxy_for_path,     :class_name => 'Resource'
  has_one    :proxy,              :primary_key => :path, :foreign_key => :proxy_for_path,     :class_name => 'Resource', :conditions => 'is_proxy = 1', :dependent => :destroy

  has_one    :folder_entry,       :primary_key => :path, :foreign_key => :proxy_for_path,     :class_name => 'Resource', :conditions => 'is_folder_entry = 1', :dependent => :destroy

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

  after_destroy :update_manifest!

  def is_manifest?
    path == ResearchObject::MANIFEST_PATH
  end

  def description

    graph = RDF::Graph.new

    ro_uri = RDF::URI(research_object.uri)
    uri    = resource_uri

    if is_manifest?
      graph << [uri, RDF.type,      RO.Manifest]
      graph << [uri, RDF.type,      ORE.ResourceMap]
      graph << [uri, ORE.describes, ro_uri]
    end

    if is_resource
      graph << [uri, RDF.type, RO.Resource]
    end

    if is_aggregated
      graph << [uri, RDF.type, ORE.AggregatedResource]
    end

    if is_proxy
      graph << [uri, RDF.type,     ORE.Proxy]
      graph << [uri, ORE.proxyIn,  ro_uri.join(proxy_in_path)]
      graph << [uri, ORE.proxyFor, ro_uri.join(proxy_for_path)]
    end

    if is_annotation
      graph << [uri, RDF.type, RO.AggregatedAnnotation]
      graph << [uri, RDF.type, AO.Annotation]
      graph << [uri, AO.body,  ro_uri.join(ao_body_path)]

      annotation_resources.each do |resource|
        graph << [uri, RO.annotatesAggregatedResource, ro_uri.join(resource.resource_path)]
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
      graph << [folder_uri, ORE.isAggregatedBy, RDF::URI(folder.aggregated_by.uri)] if folder.aggregated_by_path

      folder.aggregates.each do |aggregate|
        graph << [folder_uri, ORE.aggregates, RDF::URI(aggregate.uri)]
        graph << [RDF::URI(aggregate.uri), ORE.isAggregatedBy, folder_uri]
      end
    end

    if is_folder
      graph << [uri, RDF.type, RO.Resource]
      graph << [uri, RDF.type, RO.Folder]
      graph << [uri, RDF.type, ORE.AggregatedResource]
      graph << [uri, RDF.type, ORE.Aggregation]

      resource_map = Resource.find(:first, :conditions => { :path => resource_map_path })

      graph << [uri, ORE.isDescribedBy, ro_uri.join(resource_map_path)]
    end

    if is_folder_entry
      graph << [uri, RDF.type,     ORE.Proxy]
      graph << [uri, RDF.type,     RO.FolderEntry]
      graph << [uri, ORE.proxyIn,  ro_uri.join(proxy_in_path)]
      graph << [uri, ORE.proxyFor, ro_uri.join(proxy_for_path)]
    end

    name = path.split("/").last if path

    graph << [uri, RDF::DC.created, created_at.to_datetime] if created_at
    graph << [uri, RDF::DC.creator, RDF::URI(creator_uri)]  if creator_uri
    graph << [uri, RO["name"],      name]                   if name

    if content_blob && !is_manifest?
      graph << [uri, RO.filesize, content_blob.size] if content_blob.size
      graph << [uri, RO.checksum, RDF::URI("urn:MD5:#{content_blob.md5}")]
    end

    graph
  end

  def resource_uri
    RDF::URI(research_object.uri) + path
  end

  def uri
    RDF::URI(research_object.uri) + path
  end

  def name
    URI(path).path.split("/").last
  end

  def update_graph!

    new_description = create_rdf_xml { |graph| graph << description }

    unless is_resource
      content_blob.destroy if content_blob
      update_attribute(:content_blob, ContentBlob.new(:data => new_description))
    end
  end

  def annotations
    research_object.annotation_resources.find(:all,
        :conditions => { :resource_path => path }).map { |ar| ar.annotation }
  end

  def merged_annotation_graphs

    result = RDF::Graph.new

    annotations.each do |annotation|
      ao_body = annotation.ao_body
      result << load_graph(ao_body.content_blob.data, ao_body.content_type)
    end

    result
  end

  def annotations_with_templates
    annotations.map do |annotation|
      template, parameters = research_object.find_template_from_graph(load_graph(annotation.ao_body.content_blob.data, annotation.ao_body.content_type), Conf.ro_templates)
      {
        :annotation => annotation,
        :template => template,
        :paramters => parameters
      }
    end
  end

  def copy_metadata
    if content_blob
      self.sha1 = content_blob.calc_sha1
      self.size = content_blob.calc_size
    else
      self.sha1 = nil
      self.size = nil
    end
  end

  def update_manifest!
    research_object.update_manifest!
  end
end
