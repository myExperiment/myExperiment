# myExperiment: app/models/research_object.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require 'rdf'
require 'rdf/raptor'

class ResearchObject < ActiveRecord::Base

  MANIFEST_PATH = ".ro/manifest.rdf"

  include ResearchObjectsHelper

  after_create :create_manifest

  belongs_to :user

  has_many :resources, :dependent => :destroy

  has_many :annotation_resources

  validates_presence_of :slug

  def uri
    Conf.base_uri + "/rodl/ROs/#{slug}/"
  end

  def creator_uri
    Conf.base_uri + "/users/#{user_id}"
  end

  def description

    ro_uri = RDF::URI(uri)

    graph = RDF::Graph.new

    graph << [ro_uri, RDF.type, RO.ResearchObject]
    graph << [ro_uri, RDF.type, ORE.Aggregation]
    graph << [ro_uri, ORE.isDescribedBy, ro_uri + MANIFEST_PATH]
    graph << [ro_uri, RDF::DC.created, created_at.to_datetime]
    graph << [ro_uri, RDF::DC.creator, RDF::URI(creator_uri)]

    graph << [RDF::URI(creator_uri), RDF.type, RDF::FOAF.Agent]

    if root_folder
      graph << [ro_uri, RO.rootFolder, RDF::URI(root_folder.uri)]
    end

    resources.each do |resource|

      if resource.is_aggregated
        graph << [ro_uri, ORE.aggregates, RDF::URI(resource.resource_uri)]
      end

      graph << resource.description
    end

    graph
  end

  def update_manifest!

    resources.reload

    manifest_body = pretty_rdf_xml(RDF::Writer.for(:rdfxml).buffer { |writer| writer << description })

    new_or_update_resource(
        :slug         => MANIFEST_PATH,
        :content_type => "application/rdf+xml",
        :data         => manifest_body,
        :force_write  => true) 
  end

  def manifest_resource
    resources.find(:first, :conditions => { :path => MANIFEST_PATH })
  end

  def root_folder
    resources.find(:first, :conditions => { :is_root_folder => true } )
  end

  def new_or_update_resource(opts = {})

    changed = []
    links = []
    location = nil

    content_type  = opts[:content_type]
    slug          = opts[:slug]
    path          = opts[:path]
    user_uri      = opts[:user_uri]
    data          = opts[:data]
    request_links = opts[:links] || {}

    if slug == ResearchObject::MANIFEST_PATH

      return [:forbidden, "Cannot overwrite the manifest", nil, []] unless opts[:force_write]

      manifest = create_resource(
        :path          => calculate_path(slug, content_type, request_links),
        :content_blob  => ContentBlob.new(:data => data),
        :creator_uri   => user_uri,
        :content_type  => content_type,
        :is_resource   => false,
        :is_aggregated => false,
        :is_proxy      => false,
        :is_annotation => false,
        :is_folder     => false)

      changed << manifest

    elsif content_type == "application/vnd.wf4ever.proxy"

      graph = load_graph(data)

      node           = graph.query([nil,  RDF.type,     ORE.proxy]).first_subject
      proxy_for_uri  = graph.query([node, ORE.proxyFor, nil      ]).first_object

      proxy = create_proxy(
        :path           => calculate_path(slug, content_type, request_links),
        :proxy_for_path => relative_uri(proxy_for_uri, uri),
        :proxy_in_path  => ".",
        :user_uri       => user_uri)

      proxy.update_graph!

      location =  proxy.uri
      links    << { :link => proxy_for_uri, :rel => ORE.proxyFor }
      changed  << proxy

    elsif content_type == "application/vnd.wf4ever.annotation"

      # Get information.

      graph = load_graph(data)

      aggregated_annotations = graph.query([nil, RDF.type, RO.AggregatedAnnotation])

      if aggregated_annotations.count != 1 # FIXME - add test case
        return [:unprocessable_entity, "The annotation must contain exactly one aggregated annotation", nil, []]
      end

      aggregated_annotation = aggregated_annotations.first_subject

      ao_body_statements = graph.query([aggregated_annotation, AO.body, nil])

      if ao_body_statements.count != 1 # FIXME - add test case
        return [:unprocessable_entity, "Annotations must contain exactly one annotation body", nil, []]
      end

      annotated_resources_statements = graph.query([aggregated_annotation, AO.annotatesResource, nil])

      if annotated_resources_statements.count == 0 # FIXME - add test case
        return [:unprocessable_entity, "Annotations must annotate one or more resources", nil, []]
      end

      ao_body_uri = ao_body_statements.first_object.to_s

      stub = create_annotation_stub(
        :user_uri       => user_uri,
        :ao_body_path   => relative_uri(ao_body_uri, uri),
        :resource_paths => annotated_resources_statements.map { |a| relative_uri(a.object, uri) } )

      annotated_resources_statements.each do |annotated_resource|
        links << { :link => annotated_resource.object, :rel => AO.annotatesResource }
      end

      stub.update_graph!

      links   << { :link => ao_body_uri, :rel => AO.body }
      changed << stub

    elsif content_type == "application/vnd.wf4ever.folder"

      folder = create_folder(
        :path     => slug,
        :user_uri => user_uri)

      proxy = create_proxy(
        :proxy_for_path => folder.path,
        :proxy_in_path  => ".",
        :user_uri       => user_uri)

      location = proxy.uri

      links << { :link => folder.resource_map.uri, :rel => ORE.isDescribedBy }
      links << { :link => folder.uri,              :rel => ORE.proxyFor      }

      changed << proxy
      changed << folder.resource_map
      changed << folder

    elsif content_type == "application/vnd.wf4ever.folderentry"

      # Obtain information to create the folder entry.

      graph = load_graph(data)

      node           = graph.query([nil,  RDF.type,     RO.FolderEntry]).first_subject
      proxy_for_uri  = graph.query([node, ORE.proxyFor, nil           ]).first_object

      # FIXME - need to check if proxy_in and proxy_for actually exists and error if not

      proxy_for_path = relative_uri(proxy_for_uri, uri)
      proxy_in_path  = opts[:path]

      # Create the folder entry

      folder_entry = create_resource(
        :path            => calculate_path(nil, 'application/vnd.wf4ever.folderentry'),
        :is_folder_entry => true,
        :proxy_in_path   => proxy_in_path,
        :proxy_for_path  => proxy_for_path,
        :content_type    => content_type,
        :creator_uri     => user_uri)

      folder_entry.proxy_for.update_attribute(:aggregated_by_path, proxy_in_path)

      folder_entry.update_graph!
      folder_entry.proxy_for.update_graph!

      location = folder_entry.uri

      links << { :link => proxy_for_uri, :rel => ORE.proxyFor }

      changed << folder_entry

    elsif request_links[AO.annotatesResource.to_s]

      path           = calculate_path(nil, content_type)
      ro_uri         = RDF::URI(uri)
      annotation_uri = ro_uri + path

      # Create an annotation body using the provided graph

      ao_body = create_aggregated_resource(
        :path         => calculate_path(slug, content_type, request_links),
        :data         => data,
        :content_type => content_type,
        :user_uri     => user_uri)

      stub = create_annotation_stub(
        :user_uri       => user_uri,
        :ao_body_path   => ao_body.path,
        :resource_paths => request_links[AO.annotatesResource.to_s].each { |resource| relative_uri(resource, uri) } )

      ao_body.update_graph!
      stub.update_graph!

      request_links[AO.annotatesResource.to_s].each do |annotated_resource_uri|
        links << { :link => annotated_resource_uri, :rel => AO.annotatesResource }
      end

      changed << stub
      changed << ao_body
      changed << ao_body.proxy

      links << { :link => stub.uri, :rel => AO.body }

      location = stub.uri

    else

      resource = create_aggregated_resource(
        :path         => calculate_path(slug, content_type, request_links),
        :data         => data,
        :content_type => content_type,
        :user_uri     => user_uri)

      changed << resource
    end

    if resource && content_type != "application/vnd.wf4ever.proxy" && !resource.is_manifest? && !request_links[AO.annotatesResource.to_s]

      proxy = resources.find(:first,
          :conditions => { :content_type   => 'application/vnd.wf4ever.proxy',
                           :proxy_in_path  => '.',
                           :proxy_for_path => resource.path })

      # Create a proxy for this resource if it doesn't exist.

      unless proxy
        proxy = create_proxy(
          :proxy_for_path => resource.path,
          :proxy_in_path  => ".",
          :user_uri       => user_uri)

        proxy.update_graph!
      end

      links << { :link => resource.uri, :rel => ORE.proxyFor }
      location = proxy.uri

      changed << proxy
    end

    location ||= resource.uri if resource

    [:created, nil, location, links, path, changed]
  end

  # opts[:path] - optional path to use for the proxy
  # opts[:proxy_for_path] - required
  # opts[:proxy_in_path] - required
  # opts[:user_uri] - optional

  def create_proxy(opts)

    # FIXME - these should be validations on the resource model
    throw "proxy_for_path required" unless opts[:proxy_for_path]
    throw "proxy_in_path required"  unless opts[:proxy_in_path]

    create_resource(
      :path           => opts[:path] || calculate_path(nil, 'application/vnd.wf4ever.proxy'),
      :is_proxy       => true,
      :proxy_for_path => opts[:proxy_for_path],
      :proxy_in_path  => opts[:proxy_in_path],
      :creator_uri    => opts[:user_uri],
      :content_type   => "application/vnd.wf4ever.proxy")
  end

  def create_annotation_stub(opts)

    # FIXME - these should be validations on the resource model
    throw "ao_body_path required"   unless opts[:ao_body_path]
    throw "resource_paths required" unless opts[:resource_paths]
    
    stub = create_resource(
      :path          => opts[:path] || calculate_path(nil, 'application/vnd.wf4ever.annotation'),
      :creator_uri   => opts[:user_uri],
      :content_type  => 'application/rdf+xml',
      :is_aggregated => true,
      :is_annotation => true,
      :ao_body_path  => opts[:ao_body_path])

    opts[:resource_paths].map do |resource_path|
      stub.annotation_resources.create(:resource_path => resource_path, :research_object => self)
    end

    stub
  end

  def create_aggregated_resource(opts)

    # Create a proxy for this resource.

    proxy = create_proxy(
      :proxy_for_path => opts[:path],
      :proxy_in_path  => ".",
      :user_uri       => opts[:user_uri])

    proxy.update_graph!

    # Create the resource.

    create_resource(
      :path          => opts[:path],
      :content_blob  => ContentBlob.new(:data => opts[:data]),
      :creator_uri   => opts[:user_uri],
      :content_type  => opts[:content_type],
      :is_resource   => true,
      :is_aggregated => true)
  end

  def create_resource_map(opts)

    create_resource(
      :path            => opts[:path] || calculate_path(nil, "application/vnd.wf4ever.folder"),
      :creator_uri     => opts[:user_uri],
      :content_type    => 'application/rdf+xml',
      :is_resource_map => true)

  end

  def create_folder(opts)

    # Create a resource map for this folder

    resource_map = create_resource_map(:user_uri => opts[:user_uri])

    # Create the folder entry

    folder = create_resource(
      :path              => opts[:path],
      :creator_uri       => opts[:user_uri],
      :content_type      => "application/vnd.wf4ever.folder",
      :resource_map_path => resource_map.path,
      :is_aggregated     => true,
      :is_root_folder    => root_folder.nil?,
      :is_folder         => true)

    folder.update_graph!
    resource_map.update_graph!

    folder
  end

  def create_resource(attributes)

    resource = resources.find_by_path(attributes[:path]) || resources.new

    # FIXME - We need to know when we should be allowed to overwrite a
    # resource.  The RO structure needs to remain consistent.

    resource.attributes = attributes
    resource.save
    resource
  end

private

  def create_manifest

    resources.create(:path => ResearchObject::MANIFEST_PATH,
                     :content_type => 'application/rdf+xml')

    update_manifest!
  end
end
