
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

  def trim_and_wrap(doc)

    doc.root.elements.each do |element|
      unless element.text.nil?

        lines = element.text.strip.split("\n")

        lines = lines[0..4] + ['...'] if lines.length > 5

        lines = lines.map do |line|
          "        #{line.strip}"
        end

        text = lines.join("\n").strip

        text = "\n        #{text}\n      " if element.attributes['encoding'] == 'base64'

        element.text = text
      end
    end

    sw = StringIO.new; doc.write(sw, 2); text = sw.string

    line_limit = 100

    lines = text.split("\n")

    lines = lines.map do |line|
      line.length > line_limit ? line[0..line_limit - 2] + '...' : line
    end

    lines.join("\n")
  end
  
  def rest_example(method, rest_name, model_name, id, show_version)

    query = { 'id' => id, 'elements' => 'all' }

    query['version'] = 1 if show_version

    ob = eval(model_name.camelize).find(id.to_i)
    doc = rest_get_request(ob, rest_name, object_url(ob), rest_name, query)

    trim_and_wrap(doc)
  end

  def rest_index_example(thing)
    doc = rest_index_request(TABLES['REST'][:data][thing]['GET'], {} )

    trim_and_wrap(doc)
  end

end

