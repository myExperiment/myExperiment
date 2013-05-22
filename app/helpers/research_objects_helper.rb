
require 'xml/libxml'

module ResearchObjectsHelper

  NAMESPACES = {
      "http://purl.org/dc/terms/"              => "dct",
      "http://www.openarchives.org/ore/terms/" => "ore",
      "http://purl.org/ao/"                    => "ao",
      "http://purl.org/wf4ever/ro#"            => "ro"
  }

  def pretty_rdf_xml(text)

    descriptions = { }

    doc = LibXML::XML::Parser.string(text).parse

    # Merge descriptions where the subject is the same.

    doc.root.find("/rdf:RDF/rdf:Description").each do |description|

      resource = description.attributes["about"]

      if descriptions[resource]

        if descriptions[resource].children.last.to_s == "\n  "
          descriptions[resource].children.last.remove!
          descriptions[resource].children << "\n"
        end

        description.each do |object|
          if object.element?
            descriptions[resource] << "\n    "
            descriptions[resource] << object
            descriptions[resource] << "\n  "
          end
        end

        description.prev.remove!
        description.remove!
      else
        descriptions[resource] = description

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

    uri     = uri.to_s
    context = context.to_s

    if (uri == context)
      candidate = "."
    elsif uri.starts_with?(context)
      candidate = uri[context.length..-1]
    end

    return uri if candidate.nil?
    return uri if URI(context).merge(candidate).to_s != uri

    candidate
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
    else
      SecureRandom.uuid
    end
  end

  def load_graph(content)
    graph = RDF::Graph.new # FIXME - this should support more than just rdf+xml
    graph << RDF::Reader.for(:rdfxml).new(content) if content
    graph
  end

  def create_rdf_xml(&blk)
    graph = RDF::Graph.new
    yield(graph)
    pretty_rdf_xml(RDF::Writer.for(:rdfxml).buffer { |writer| writer << graph })
  end

end

