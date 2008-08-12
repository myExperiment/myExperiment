
require 'lib/rest'

module MashupHelper

  def get_rest_routes(type)

    routes = []

    TABLES['REST'][:data].sort.each do |uri,methods|
      methods.each do |method,rules|
        routes << [uri,method,rules] if rules['Type'] == type
      end
    end

    routes
  end

  def get_model_attributes(rest_name)
    TABLES['Model'][:data][rest_name]
  end

  def get_example_id(rules)
    rules['Example'][rules['REST Attribute'].index('id')]
  end

  def rest_example_id(type)
    case type
      when "workflow"; return "20"
    end
  end

  def trim_and_wrap(doc)

    # Clean up the base64 sections

    doc.root.children.each do |node|
      if node["encoding"] == "base64"

        text = node.child.to_s

        lines = text.strip.split("\n")
        lines = lines[0..9] + ['...'] if lines.length > 10
        lines = lines.map do |line|
          "    #{line.strip}"
        end

        text = lines.join("\n").strip
        text = "\n    #{text}\n  "

        node.children[0].remove!
        node << text
      end
    end

    doc.to_s
  end
  
  def rest_example(method, rest_name, model_name, id, show_version)

    query = { 'id' => id, 'all_elements' => 'yes' }

    query['version'] = 1 if show_version

    ob = eval(model_name.camelize).find_by_id(id.to_i)

    return "" if ob.nil?

    doc = rest_get_request(ob, rest_name, rest_resource_uri(ob), rest_name, query)

    trim_and_wrap(doc)
  end

  def rest_index_example(thing)
    doc = rest_index_request(TABLES['REST'][:data][thing]['GET'], {} )

    trim_and_wrap(doc)
  end

  def try_it_now_link(method, uri)
    target = "#{request.protocol}#{request.host_with_port}#{uri}"
    "#{target} <input type=\"button\" value=\"Try it now\" onclick=\"javascript:getDocumentSync('#{method}', '#{target}')\" />"
  end

end

