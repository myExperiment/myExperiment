require 'rdf'
require 'rdf/raptor'

class ResearchObject < ActiveRecord::Base

  MANIFEST_PATH = ".ro/manifest.rdf"

  include ResearchObjectsHelper

  after_create :create_manifest

  belongs_to :user

  has_many :resources, :dependent => :destroy

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

    graph << [ro_uri, RDF.type, RDF::URI("http://purl.org/wf4ever/ro#ResearchObject")]
    graph << [ro_uri, RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/Aggregation")]
    graph << [ro_uri, RDF::URI("http://www.openarchives.org/ore/terms/isDescribedBy"), ro_uri + MANIFEST_PATH]
    graph << [ro_uri, RDF::DC.created, created_at.to_datetime]
    graph << [ro_uri, RDF::DC.creator, RDF::URI(creator_uri)]

    graph << [RDF::URI(creator_uri), RDF.type, RDF::FOAF.Agent]

    resources.each do |resource|

      if resource.is_aggregated
        graph << [ro_uri, RDF::URI("http://www.openarchives.org/ore/terms/aggregates"), RDF::URI(resource.resource_uri)]
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

  def new_or_update_resource(opts = {})

    changed_descriptions = []
    links = []
    location = nil

    content_type  = opts[:content_type]
    slug          = opts[:slug]
    path          = opts[:slug]
    user_uri      = opts[:user_uri]
    data          = opts[:data]
    request_links = opts[:links] || {}

    if slug == ResearchObject::MANIFEST_PATH

      path = calculate_path(slug, content_type, request_links)

      return [:forbidden, "Cannot overwrite the manifest", nil, []] unless opts[:force_write]

      resource = resources.find_by_path(path)
      resource = resources.new(:path => path) unless resource

      resource.content_blob.destroy if resource.content_blob

      resource.content_blob = ContentBlob.new(:data => data)
      resource.creator_uri = user_uri
      resource.content_type = content_type
      resource.name = path.split("/").last if path

      resource.is_resource   = false
      resource.is_aggregated = false
      resource.is_proxy      = false
      resource.is_annotation = false
      resource.is_folder     = false


      resource.save

      changed_descriptions << resource.path

    elsif content_type == "application/vnd.wf4ever.proxy"

      path = calculate_path(slug, content_type, request_links)

      # Obtain information to create the proxy.

      graph = load_graph(data)

      node           = graph.query([nil,  RDF.type,     ORE.proxy]).first_subject
      proxy_for_uri  = graph.query([node, ORE.proxyFor, nil           ]).first_object

      # Contruct the proxy.

      ro_uri         = RDF::URI(uri)
      proxy_uri      = ro_uri + path
      proxy_in_uri   = ro_uri
      proxy_for_path = relative_uri(proxy_for_uri, uri)
      proxy_in_path  = relative_uri(proxy_in_uri, uri)

      proxy_body = create_rdf_xml do |graph|
        graph << [proxy_uri, RDF.type,     ORE.Proxy]
        graph << [proxy_uri, ORE.proxyIn,  proxy_in_uri]
        graph << [proxy_uri, ORE.proxyFor, proxy_for_uri]
      end

      proxy = resources.find_by_path(path)
      proxy = resources.new(:path => path) unless proxy

      proxy.content_blob.destroy if proxy.content_blob

      proxy.is_proxy       = true
      proxy.proxy_for_path = proxy_for_path
      proxy.proxy_in_path  = proxy_in_path
      proxy.content_blob   = ContentBlob.new(:data => proxy_body)
      proxy.creator_uri    = user_uri
      proxy.content_type   = content_type
      proxy.name           = path.split("/").last

      proxy.save

      location = proxy.uri
      links << { :link => proxy_for_uri, :rel => ORE.proxyFor }

      changed_descriptions << proxy.path

    elsif content_type == "application/vnd.wf4ever.annotation"

      path = calculate_path(slug, content_type, request_links)

      resource = resources.find_by_path(path)
      resource = resources.new(:path => path) unless resource

      resource.content_blob.destroy if resource.content_blob

      resource.content_blob = ContentBlob.new(:data => data)
      resource.creator_uri = user_uri
      resource.content_type = content_type
      resource.name = path.split("/").last if path

      # Creation of an annotation stub directly

      resource.is_resource   = false
      resource.is_aggregated = true
      resource.is_proxy      = false
      resource.is_annotation = true
      resource.is_folder     = false

      graph = load_graph(resource.content_blob.data)

      aggregated_annotations = graph.query([nil, RDF.type, RDF::URI("http://purl.org/wf4ever/ro#AggregatedAnnotation")])

      if aggregated_annotations.count != 1 # FIXME - add test case
        return [:unprocessable_entity, "The annotation must contain exactly one aggregated annotation", nil, []]
      end

      aggregated_annotation = aggregated_annotations.first_subject

      ao_body_statements = graph.query([aggregated_annotation, RDF::URI("http://purl.org/ao/body"), nil])

      if ao_body_statements.count != 1 # FIXME - add test case
        return [:unprocessable_entity, "Annotations must contain exactly one annotation body", nil, []]
      end

      ao_body_uri = ao_body_statements.first_object.to_s

      resource.ao_body_path = relative_uri(ao_body_uri, uri)

      annotated_resources_statements = graph.query([aggregated_annotation, RDF::URI("http://purl.org/ao/annotatesResource"), nil])

      if annotated_resources_statements.count == 0 # FIXME - add test case
        return [:unprocessable_entity, "Annotations must annotate one or more resources", nil, []]
      end

      annotated_resources_statements.each do |annotated_resource|
        resource.annotation_resources.build(:resource_path => relative_uri(annotated_resource.object, uri))
        links << { :link => annotated_resource.object.to_s, :rel => "http://purl.org/ao/annotatesResource" }
      end

      links << { :link => ao_body_uri, :rel => "http://purl.org/ao/body" }


      resource.save

      changed_descriptions << resource.path

    elsif content_type == "application/vnd.wf4ever.folder"

      path = calculate_path(slug, content_type, request_links)

      resource = resources.find_by_path(path)
      resource = resources.new(:path => path) unless resource

      resource.content_blob.destroy if resource.content_blob

      resource.content_blob = ContentBlob.new(:data => data)
      resource.creator_uri = user_uri
      resource.content_type = content_type
      resource.name = path.split("/").last if path


      resource.is_resource   = false
      resource.is_aggregated = true
      resource.is_proxy      = false
      resource.is_annotation = false
      resource.is_folder     = true
      
      # Create a resource map for this folder

      resource_uri = resource.resource_uri.to_s

      resource_map_path = ".ro/resource_maps/#{SecureRandom.uuid}"
      resource_map_uri  = uri + resource_map_path

      resource_map_graph = RDF::Graph.new
      resource_map_graph << [RDF::URI(resource_map_uri), RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/ResourceMap")]
      resource_map_graph << [RDF::URI(resource_map_uri), RDF::URI("http://www.openarchives.org/ore/terms/describes"), RDF::URI(resource_uri)]

      resource_map_body = pretty_rdf_xml(RDF::Writer.for(:rdfxml).buffer { |writer| writer << resource_map_graph } )

      # FIXME - this should be a recursive call

      resource_map_attributes = {
        :content_blob    => ContentBlob.new(:data => resource_map_body),
        :creator_uri     => user_uri,
        :content_type    => 'application/vnd.wf4ever.folder',
        :is_resource_map => true,
        :path            => resource_map_path
      }

      resources.create(resource_map_attributes)

      resource.resource_map_path = resource_map_path

      links << { :link => resource_map_uri, :rel => "http://www.openarchives.org/ore/terms/isDescribedBy" }
      links << { :link => resource_uri,     :rel => "http://www.openarchives.org/ore/terms/proxyFor"      }

      changed_descriptions << resource_map_path


      resource.save

      changed_descriptions << resource.path

    elsif content_type == "application/vnd.wf4ever.folderentry"

      path = calculate_path(nil, 'application/vnd.wf4ever.folderentry')

      # Obtain information to create the folder entry.

      graph = load_graph(data)

      node           = graph.query([nil,  RDF.type,     RO.FolderEntry]).first_subject
      proxy_for_uri  = graph.query([node, ORE.proxyFor, nil           ]).first_object

      proxy_for_path = relative_uri(proxy_for_uri, uri)
      proxy_in_path  = opts[:path]
      proxy_in_uri   = uri + proxy_in_path

      # Create the folder entry

      folder_entry = resources.new(:path => path)

      folder_entry_uri = RDF::URI(folder_entry.uri)

      folder_entry_body = create_rdf_xml do |graph|
        graph << [folder_entry_uri, RDF.type, ORE.Proxy]
        graph << [folder_entry_uri, RDF.type, RO.FolderEntry]
        graph << [folder_entry_uri, ORE.proxyIn, RDF::URI(proxy_in_uri)]
        graph << [folder_entry_uri, ORE.proxyFor, RDF::URI(proxy_for_uri)]
      end

      folder_entry.is_folder_entry = true
      folder_entry.content_blob    = ContentBlob.new(:data => folder_entry_body)
      folder_entry.proxy_in_path   = proxy_in_path
      folder_entry.proxy_for_path  = proxy_for_path
      folder_entry.content_type    = content_type
      folder_entry.creator_uri     = user_uri
      folder_entry.name            = path.split("/").last if path

      folder_entry.save

      folder_entry.proxy_for.update_attribute(:aggregated_by_path, proxy_in_path)

      location = folder_entry.uri

      links << { :link => proxy_for_uri, :rel => "http://www.openarchives.org/ore/terms/proxyFor" }

    elsif request_links["http://purl.org/ao/annotatesResource"]

      path           = calculate_path(nil, content_type)
      ro_uri         = RDF::URI(uri)
      annotation_uri = ro_uri + path


      # Create an annotation body using the provided graph

      # Process ao:annotatesResource links by creating annotation stubs using the
      # given resource as an ao:body.

      ao_body_path = calculate_path(slug, content_type, request_links)

      ao_body = resources.find_by_path(path)
      ao_body = resources.new(:path => path) unless ao_body

      ao_body.content_blob.destroy if ao_body.content_blob

      ao_body.content_blob  = ContentBlob.new(:data => data)
      ao_body.creator_uri   = user_uri
      ao_body.content_type  = content_type
      ao_body.name          = ao_body_path.split("/").last
      ao_body.is_resource   = true
      ao_body.is_aggregated = true

      ao_body.save
      # FIXME - no proxy is created for this ao:body resource

      changed_descriptions << ao_body.path

      annotation_rdf = create_rdf_xml do |graph|
        graph << [annotation_uri, RDF.type, RO.AggregatedAnnotation]
        graph << [annotation_uri, RDF.type, AO.Annotation]
        graph << [annotation_uri, AO.body,  RDF::URI(ao_body.uri)]

        request_links["http://purl.org/ao/annotatesResource"].each do |annotated_resource_uri|
          graph << [annotation_uri, AO.annotatesResource, RDF::URI(annotated_resource_uri)]
        end
      end

      annotation_stub = resources.new({
        :creator_uri   => user_uri,
        :path          => calculate_path(nil, 'application/vnd.wf4ever.annotation'),
        :content_blob  => ContentBlob.new(:data => annotation_rdf),
        :content_type  => 'application/vnd.wf4ever.annotation',
        :is_annotation => true,
        :ao_body_path  => ao_body.path
      })

      request_links["http://purl.org/ao/annotatesResource"].each do |annotated_resource_uri|
        annotation_stub.annotation_resources.build(:resource_path => relative_uri(annotated_resource_uri, uri))
        links << { :link => annotated_resource_uri, :rel => "http://purl.org/ao/annotatesResource" }
      end

      annotation_stub.save

      changed_descriptions << annotation_stub.path

      links << { :link => annotation_stub.uri, :rel => "http://purl.org/ao/body" }

      location = uri + annotation_stub.path

    else

      path = calculate_path(slug, content_type, request_links)

      resource = resources.find_by_path(path)
      resource = resources.new(:path => path) unless resource

      resource.content_blob.destroy if resource.content_blob

      resource.content_blob  = ContentBlob.new(:data => data)
      resource.creator_uri   = user_uri
      resource.content_type  = content_type
      resource.name          = path.split("/").last
      resource.is_resource   = true
      resource.is_aggregated = true

      resource.save

      changed_descriptions << resource.path
    end

    if resource && content_type != "application/vnd.wf4ever.proxy" && !resource.is_manifest? && !request_links["http://purl.org/ao/annotatesResource"]

      resource_uri = resource.resource_uri.to_s

      relative_resource_uri = relative_uri(resource_uri, uri)

      proxy = resources.find(:first,
          :conditions => { :content_type   => 'application/vnd.wf4ever.proxy',
                           :proxy_in_path  => '.',
                           :proxy_for_path => relative_resource_uri })

      if proxy.nil?
        proxy_slug = ".ro/proxies/#{SecureRandom.uuid}"
      else
        proxy_slug = proxy.path
      end

      proxy_body = pretty_rdf_xml(RDF::Writer.for(:rdfxml).buffer { |writer| writer << resource.generate_proxy(proxy_slug) } )

      # FIXME - this should be a recursive call

      proxy_attributes = {
        :content_blob   => ContentBlob.new(:data => proxy_body),
        :proxy_in_path  => '.',
        :proxy_for_path => relative_resource_uri,
        :creator_uri    => user_uri,
        :content_type   => 'application/vnd.wf4ever.proxy',
        :is_proxy       => true,
        :path           => proxy_slug
      }

      if proxy.nil?
        proxy = resources.create(proxy_attributes)
      else
        proxy.content_blob.destroy
        proxy.update_attributes(proxy_attributes)
      end

      links << { :link => resource_uri, :rel => "http://www.openarchives.org/ore/terms/proxyFor" }
      location = proxy.uri

      changed_descriptions << proxy_slug
    end

    location ||= resource_uri

    [:created, nil, location, links, path, changed_descriptions]
  end

private

  def create_manifest

    resources.create(:path => ResearchObject::MANIFEST_PATH,
                     :content_blob => ContentBlob.new(:data => "Dummy content"),
                     :content_type => 'application/rdf+xml')

    update_manifest!
  end
end
