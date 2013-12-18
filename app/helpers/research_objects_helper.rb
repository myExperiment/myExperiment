# myExperiment: app/helpers/research_objects_helper.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require 'securerandom'
require 'xml/libxml'
require 'uri'


module ResearchObjectsHelper

  # Add support for app:// scheme
  # http://www.w3.org/TR/app-uri/
  class APP < URI::Generic
      USE_REGISTRY=true
      ## FIXME: Why do I also need to redeclare this method?
      def self.use_registry
        true
      end
          
      COMPONENT = [
          :scheme,
          :registry,
          :path, :opaque,
          :query,
          :fragment
      ].freeze
      def self.component
        self::COMPONENT
      end
  end
  URI.scheme_list['APP'] = APP

  NAMESPACES = {
      "http://www.w3.org/1999/02/22-rdf-syntax-ns#" => "rdf",
      "http://www.w3.org/2000/01/rdf-schema#"       => "rdfs",
      "http://purl.org/dc/terms/"                   => "dct",
      "http://www.openarchives.org/ore/terms/"      => "ore",
      "http://purl.org/ao/"                         => "ao",
      "http://purl.org/wf4ever/ro#"                 => "ro",
      "http://www.w3.org/ns/prov#"                  => "prov",
      "http://xmlns.com/foaf/0.1/"                  => "foaf",
      "http://www.w3.org/ns/oa#"                    => "oa",
      "http://purl.org/pav/"                        => "pav",
      "http://purl.org/wf4ever/bundle#"             => "bundle",
      "http://purl.org/dc/elements/1.1/"            => "dce",
      "http://purl.org/wf4ever/roterms#"            => "roterms",
      "http://purl.org/wf4ever/wfprov#"             => "wfprov",
      "http://purl.org/wf4ever/wfdesc#"             => "wfdesc",
      "http://purl.org/wf4ever/wf4ever#"            => "wf4ever",
      "http://ns.taverna.org.uk/2012/tavernaprov/"  => "tavernaprov",
      "http://www.w3.org/2011/content#"             => "content",
      "http://www.w3.org/2002/07/owl#"              => "owl"

  }

  private

  def shorten_uri(uri)
    uri = uri.to_s

    NAMESPACES.each do |namespace, prefix|
      if uri.starts_with?(namespace)
        return "#{prefix}:#{uri[namespace.length..-1]}"
      end
    end

    uri
  end

  def pretty_rdf_xml(text)

    descriptions = { }

    doc = LibXML::XML::Parser.string(text).parse

    # Merge descriptions where the subject is the same.

    doc.root.find("/rdf:RDF/rdf:Description").each do |description|

      # FIXME: The following attribute access is case sensitive.

      if description.attributes["about"]
        key = "about  #{description.attributes["about"]}"
      else
        key = "nodeID #{description.attributes["nodeID"]}"
      end

      if descriptions[key]

        if descriptions[key].children.last.to_s == "\n  "
          descriptions[key].children.last.remove!
          descriptions[key].children << "\n"
        end

        description.each do |object|
          if object.element?
            descriptions[key] << "\n    "
            descriptions[key] << object
            descriptions[key] << "\n  "
          end
        end

        description.prev.remove!
        description.remove!
      else
        descriptions[key] = description

        description.prev = XML::Node.new_text("\n  ")
      end
    end

    doc.root << XML::Node.new_text("\n")

    # Adjust namespaces to human readable names

    namespaces = { "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#" }

    doc.root.find("/rdf:RDF/rdf:Description/*").each do |object|

      next unless object.element?
      next unless object.namespaces.namespace.prefix == "ns0"

      href = object.namespaces.namespace.href
      prefix = NAMESPACES[href]

      namespaces[prefix] = href unless namespaces[prefix]

      if prefix
        el = XML::Node.new(prefix + ":" + object.name)

        # Copy attributes

        object.attributes.each do |attr|
          if attr.ns?
            el.attributes[attr.ns.prefix + ":" + attr.name] = attr.value
          else
            el.attributes[attr.name] = attr.value
          end
        end

        # Move children

        object.children.each do |child|
          el << child.remove!
        end

        object.next = el
        object.remove!
      end
    end

    # Add namespaces

    namespaces.delete("rdf")

    namespaces.each do |prefix, href|
      next if prefix == "rdf"
      LibXML::XML::Namespace.new(doc.root, prefix, href)
    end

    text = doc.to_s

    text.gsub!(/" xmlns:/, "\"\n         xmlns:") # FIXME - do this without affecting the entire document

    text
  end

  def relative_uri(uri, context)

    uri     = URI.parse(uri.to_s)
    context = URI.parse(context.to_s)
    absolute = URI.parse("app://99f40c6f-15ad-4880-955a-f87e4dfb544d/")

    if context.relative?
        ## If they are both relative, e.g. "/fred/soup" and "/fred",
        # then make them both temporarily absolute. 
        # If the uri is not relative here, then we're still OK, as the
        # fairly unique context won't be leaked out.
        context = absolute.merge context
        uri = absolute.merge uri
    elsif uri.relative?
        return uri.to_s
    end
#
#    elsif uri.starts_with?(context)
#      candidate = uri[context.length..-1]
#    end
#
#    return uri if candidate.nil?
#    return uri if URI(context).merge(candidate).to_s != uri
#
#    candidate
     return uri.route_from(context).to_s
  end

  def merge_graphs_aux(node, bnodes)
    if node.class == RDF::Node
      if bnodes[node]
        bnodes[node]
      else
        bnodes[node] = RDF::Node.new
      end
    else
      node
    end
  end

  def merge_graphs(graphs)

    result = RDF::Graph.new

    graphs.each do |graph|

      bnodes = {}

      graph.statements.each do |subject, predicate, object|
        result << [merge_graphs_aux(subject,   bnodes),
                   merge_graphs_aux(predicate, bnodes),
                   merge_graphs_aux(object,    bnodes)]
      end
    end

    result
  end

  def parse_links(headers)

    links = {}

    link_headers = headers["Link"]

    if link_headers
      link_headers.split(",").each do |link|
        matches = link.strip.match(/<([^>]*)>\s*;.*rel\s*=\s*"?([^;"]*)"?/)
        if matches
          links[matches[2]] ||= []
          links[matches[2]] << matches[1]
        end
      end
    end

    links
  end

  def calculate_path(path, content_type, links = {})

    return path if path

    case content_type
    when "application/vnd.wf4ever.proxy"
      ".ro/proxies/#{SecureRandom.uuid}"
    when "application/vnd.wf4ever.annotation"
      ".ro/annotations/#{SecureRandom.uuid}"
    when "application/vnd.wf4ever.folder"
      ".ro/folders/#{SecureRandom.uuid}"
    when "application/vnd.wf4ever.folderentry"
      ".ro/entries/#{SecureRandom.uuid}"
    when "application/vnd.wf4ever.folder"
      ".ro/resource_maps/#{SecureRandom.uuid}"
    else
      SecureRandom.uuid
    end
  end

  def load_graph(content, opts = {})
  
    content_type = opts[:content_type] || "application/rdf+xml"
    base_uri     = opts[:base_uri]

    case content_type
    when "application/rdf+xml"
      format = :rdfxml
    when "text/turtle", "application/x-turtle"
      format = :turtle
    end

    graph = RDF::Graph.new
    graph << RDF::Reader.for(format).new(content, :base_uri => base_uri) if content
    graph
  end

  RDF_NS = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'

  def render_rdf_xml(graph, opts = {})

    document = LibXML::XML::Document.new

    document.root = LibXML::XML::Node.new('rdf:RDF')
    LibXML::XML::Namespace.new(document.root, 'rdf', RDF_NS)

    graph.each do |subject, predicate, object|

      description = LibXML::XML::Node.new('rdf:Description')

      if subject.anonymous?
        description["rdf:nodeID"] = subject.id
      else
        description["rdf:about"] = relative_uri(subject.to_s, opts[:base_uri])
      end

      # Split the predicate URI into a namespace and a term.

      match = predicate.to_s.match(/^(.*[\/#])([^\/#]+)$/)

      namespace = match[1]
      term = match[2]

      if namespace == RDF_NS
        statement = LibXML::XML::Node.new("rdf:#{term}")
      else
        statement = LibXML::XML::Node.new("ns0:#{term}")
        LibXML::XML::Namespace.new(statement, 'ns0', namespace)
      end

      if object.literal?

        statement['rdf:datatype'] = object.datatype.to_s if object.has_datatype?
        statement['rdf:language'] = object.language.to_s if object.has_language?

        statement << object.to_s

      elsif object.resource?

        if object.anonymous?
          statement['rdf:nodeID'] = object.id
        else
          statement['rdf:resource'] = relative_uri(object.to_s, opts[:base_uri])
        end

      end

      description << statement
      document.root << description
    end

    document.to_s
  end

  def render_rdf(graph, opts = {})
    if opts[:format] == :rdfxml || opts[:format].nil?
      render_rdf_xml(graph, opts)
    else
      RDF::Writer.for(opts[:format]).buffer(:base_uri => opts[:base_uri]) { |writer| writer << graph }
    end
  end

  def create_rdf_xml(opts={}, &blk)
    graph = RDF::Graph.new
    yield(graph)
    pretty_rdf_xml(render_rdf(graph, opts))
  end

  def resource_path_fixed(context, resource)

    resources_path = polymorphic_path([context, :items])

    ore_path = resource.ore_path

    if resource.is_root_folder?
      resources_path
    elsif ore_path
      "#{resources_path}/#{ore_path}"
    else
      throw "No ORE path to this resource"
    end
  end

  def parent_folders(resource)

    folders = []

    return [] if resource.is_root_folder

    while resource.folder_entry.proxy_in.is_root_folder == false
      resource = resource.folder_entry.proxy_in
      folders << resource
    end

    folders.reverse
  end

  def item_uri(item)
    polymorphic_url([item.research_object.context, :items]) + "/" + item.ore_path
  end

  def item_uri_with_resource(item, resource)
    item_uri(item) + "?" + { :resource => resource }.to_query
  end

  def resource_label(resource, statements)

    label = statements.query([resource, RDF::RDFS.label, nil]).first_literal

    return label if label

    resource
  end

  def item_link(item, resource, statements)
    link_to(h(resource_label(resource, statements)), item_uri_with_resource(item, resource))
  end

  def annotate_resources(research_object, resource_uris, body_graph, content_type = 'application/rdf+xml')
    research_object.create_annotation(
        :body_graph   => body_graph,
        :content_type => content_type,
        :resources    => resource_uris,
        :creator_uri  => "/users/#{current_user.id}")
  end

  def post_process_file(research_object, data, resource_uri)

    # Process robundle

    if data[0..3] == "PK\x03\x04"

      begin
        zip_file = Tempfile.new('workflow_run.zip.')
        zip_file.binmode
        zip_file.write(data)
        zip_file.close
        
        Zip::ZipFile.open(zip_file.path) { |zip|

          wfdesc = zip.get_entry(".ro/annotations/workflow.wfdesc.ttl").get_input_stream.read
          wfprov = zip.get_entry("workflowrun.prov.ttl").get_input_stream.read

          annotate_resources(research_object, [resource_uri], wfdesc, 'text/turtle')
          annotate_resources(research_object, [resource_uri], wfprov, 'text/turtle')
        }

      rescue
        raise unless Rails.env == "production"
      end
    end
  end

  def transform_wf(research_object, resource_uri)
    format = "application/vnd.taverna.t2flow+xml"
    token = Conf.wf_ro_service_bearer_token
    uri = Wf4Ever::TransformationClient.create_job(Conf.wf_ro_service_uri, resource_uri.to_s, format, research_object.uri, token)
puts "      [Conf.wf_ro_service_uri, resource_uri, format, @pack.research_object.uri, token] = #{      [Conf.wf_ro_service_uri, resource_uri, format, research_object.uri, token].inspect}"
    puts "################## Transforming at " + uri

    uri
  end
end

