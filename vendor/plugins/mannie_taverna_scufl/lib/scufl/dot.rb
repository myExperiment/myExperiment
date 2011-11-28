module Scufl
  
  # This class enables you to write the script will will be used by dot
  # (which is part of GraphViz[http://www.graphviz.org/Download.php])
  # to generate the image showing the structure of a given model.
  # To get started quickly, you could try:
  #   out_file = File.new("path/to/file/you/want/the/dot/script/to/be/written", "w+")
  #   workflow = File.new("path/to/workflow/file", "r").read
  #   model = Scufl::Parser.new.parse(workflow)
  #   Scufl::Dot.new.write_dot(out_file, model)
  #   `dot -Tpng -o"path/to/the/output/image" #{out_file.path}`
  class Dot

    @@processor_colours = {
      'apiconsumer' => 'palegreen',
      'beanshell' => 'burlywood2',
      'biomart' => 'lightcyan2',                      
      'local' => 'mediumorchid2',
      'biomobywsdl' => 'darkgoldenrod1',
      'biomobyobject' => 'gold',
      'biomobyparser' => 'white',
      'inferno' => 'violetred1',
      'notification' => 'mediumorchid2',
      'rdfgenerator' => 'purple',
      'rserv' => 'lightgoldenrodyellow',
      'seqhound' => '#836fff',
      'soaplabwsdl' => 'lightgoldenrodyellow',
      'stringconstant' => 'lightsteelblue',
      'talisman' => 'plum2',
      'bsf' => 'burlywood2',
      'abstractprocessor' => 'lightgoldenrodyellow',
      'rshell' => 'lightgoldenrodyellow',
      'arbitrarywsdl' => 'darkolivegreen3',
      'workflow' => 'crimson'}
    
    @@fill_colours = %w{white aliceblue antiquewhite beige}
    
    @@ranksep = '0.22'
    @@nodesep = '0.05'
    
    # Creates a new dot object for interaction.
    def initialize
      # @port_style IS CURRENTLY UNUSED. IGNORE!!!
      @port_style = 'none' # 'all', 'bound' or 'none'
    end
    
    # Writes to the given stream (File, StringIO, etc) the script to generate
    # the image showing the internals of the given workflow model.  
    # === Usage
    #   stream = File.new("path/to/file/you/want/the/dot/script/to/be/written", "w+")
    #   workflow = .......
    #   model = Scufl::Parser.new.parse(workflow)
    #   Scufl::Dot.new.write_dot(stream, model)
    def write_dot(stream, model)
      stream.puts 'digraph scufl_graph {'
      stream.puts ' graph ['
      stream.puts '  style=""'
      stream.puts '  labeljust="left"'
      stream.puts '  clusterrank="local"'
      stream.puts "  ranksep=\"#@@ranksep\""
      stream.puts "  nodesep=\"#@@nodesep\""
      stream.puts ' ]'
      stream.puts
      stream.puts ' node ['
      stream.puts '  fontname="Helvetica",'
      stream.puts '  fontsize="10",'
      stream.puts '  fontcolor="black", '
      stream.puts '  shape="box",'
      stream.puts '  height="0",'
      stream.puts '  width="0",'
      stream.puts '  color="black",'
      stream.puts '  fillcolor="lightgoldenrodyellow",'
      stream.puts '  style="filled"'
      stream.puts ' ];'
      stream.puts
      stream.puts ' edge ['
      stream.puts '  fontname="Helvetica",'
      stream.puts '  fontsize="8",'
      stream.puts '  fontcolor="black",'
      stream.puts '  color="black"'
      stream.puts ' ];'
      write_workflow(stream, model)
      stream.puts '}'
      
      stream.flush
    end
    
    def write_workflow(stream, model, prefix="", name="", depth=0) # :nodoc:
      if name != ""
        stream.puts "subgraph cluster_#{prefix}#{name} {"
        stream.puts " label=\"#{name}\""
        stream.puts ' fontname="Helvetica"'
        stream.puts ' fontsize="10"'
        stream.puts ' fontcolor="black"'
        stream.puts ' clusterrank="local"'
        stream.puts " fillcolor=\"#{@@fill_colours[depth % @@fill_colours.length]}\""
        stream.puts ' style="filled"'
      end
      model.processors.each {|processor| write_processor(stream, processor, prefix, depth)}
      write_source_cluster(stream, model.sources, prefix)
      write_sink_cluster(stream, model.sinks, prefix)
      model.links.each {|link| write_link(stream, link, model, prefix)}
      model.coordinations.each {|coordination| write_coordination(stream, coordination, model, prefix)}
      if name != ""
        stream.puts '}'
      end
    end
    
    def write_processor(stream, processor, prefix, depth) # :nodoc:
      # nested workflows
      if processor.model
        write_workflow(stream, processor.model, prefix + processor.name, processor.name, depth.next)
      else
        stream.puts " \"#{prefix}#{processor.name}\" ["
        stream.puts "  fillcolor=\"#{get_colour processor.type}\","
        stream.puts '  shape="box",'
        stream.puts '  style="filled",'
        stream.puts '  height="0",'
        stream.puts '  width="0",'
        stream.puts "  label=\"#{processor.name}\""
        stream.puts ' ];'
      end
    end
    
    def write_source_cluster(stream, sources, prefix) # :nodoc:
      if sources.length > 0
        stream.puts " subgraph cluster_#{prefix}sources {"
        stream.puts '  style="dotted"'
        stream.puts '  label="Workflow Inputs"'
        stream.puts '  fontname="Helvetica"'
        stream.puts '  fontsize="10"'
        stream.puts '  fontcolor="black"'
        stream.puts '  rank="same"'
        stream.puts " \"#{prefix}WORKFLOWINTERNALSOURCECONTROL\" ["
        stream.puts '  shape="triangle",'
        stream.puts '  width="0.2",'
        stream.puts '  height="0.2",'
        stream.puts '  fillcolor="brown1"'
        stream.puts '  label=""'
        stream.puts ' ]'
        sources.each {|source| write_source(stream, source, prefix)}
        stream.puts ' }'
      end
    end
    
    def write_source(stream, source, prefix) # :nodoc:
      stream.puts " \"#{prefix}WORKFLOWINTERNALSOURCE_#{source.name}\" ["
      stream.puts '   shape="box",'
      stream.puts "   label=\"#{source.name}\""
      stream.puts '   width="0",'
      stream.puts '   height="0",'
      stream.puts '   fillcolor="skyblue"'
      stream.puts ' ]' 
    end
    
    def write_sink_cluster(stream, sinks, prefix) # :nodoc:
      if sinks.length > 0
        stream.puts " subgraph cluster_#{prefix}sinks {"
        stream.puts '  style="dotted"'
        stream.puts '  label="Workflow Outputs"'
        stream.puts '  fontname="Helvetica"'
        stream.puts '  fontsize="10"'
        stream.puts '  fontcolor="black"'
        stream.puts '  rank="same"'
        stream.puts " \"#{prefix}WORKFLOWINTERNALSINKCONTROL\" ["
        stream.puts '  shape="invtriangle",'
        stream.puts '  width="0.2",'
        stream.puts '  height="0.2",'
        stream.puts '  fillcolor="chartreuse3"'
        stream.puts '  label=""'
        stream.puts ' ]'
        sinks.each {|sink| write_sink(stream, sink, prefix)}
        stream.puts ' }'
      end
    end
    
    def write_sink(stream, sink, prefix) # :nodoc:
      stream.puts " \"#{prefix}WORKFLOWINTERNALSINK_#{sink.name}\" ["
      stream.puts '   shape="box",'
      stream.puts "   label=\"#{sink.name}\""
      stream.puts '   width="0",'
      stream.puts '   height="0",'
      stream.puts '   fillcolor="lightsteelblue2"'
      stream.puts ' ]'     
    end
    
    def write_link(stream, link, model, prefix) # :nodoc:
      if model.sources.select{|s| s.name == link.source} != []
        stream.write " \"#{prefix}WORKFLOWINTERNALSOURCE_#{link.source}\""
      else 
        processor = model.processors.select{|p| p.name == link.source.split(':')[0]}[0]
        if processor.model
          stream.write " \"#{prefix}#{processor.name}WORKFLOWINTERNALSINK_#{link.source.split(':')[1]}\""
        else
          stream.write " \"#{prefix}#{processor.name}\""
        end
      end
      stream.write '->'
      if model.sinks.select{|s| s.name == link.sink} != []
        stream.write "\"#{prefix}WORKFLOWINTERNALSINK_#{link.sink}\""
      else 
        processor = model.processors.select{|p| p.name == link.sink.split(':')[0]}[0]
        if processor.model
          stream.write "\"#{prefix}#{processor.name}WORKFLOWINTERNALSOURCE_#{link.sink.split(':')[1]}\""
        else
          stream.write "\"#{prefix}#{processor.name}\""
        end
      end
      stream.puts ' ['
      stream.puts ' ];'
    end
    
    def write_coordination(stream, coordination, model, prefix) # :nodoc:
      stream.write " \"#{prefix}#{coordination.controller}"
      processor = model.processors.select{|p| p.name == coordination.controller}[0]
      if processor.model
        stream.write 'WORKFLOWINTERNALSINKCONTROL'
      end
      stream.write '"->"'
      stream.write "#{prefix}#{coordination.target}\""
      processor = model.processors.select{|p| p.name == coordination.target}[0]
      if processor.model
        stream.write 'WORKFLOWINTERNALSOURCECONTROL'
      end
      stream.puts ' ['
      stream.puts '  color="gray",'
      stream.puts '  arrowhead="odot",'
      stream.puts '  arrowtail="none"'
      stream.puts ' ];'
    end
    
    def get_colour(processor_name) # :nodoc:
      colour = @@processor_colours[processor_name]
      if colour
        colour
      else 
        'white'
      end  
    end
    
    # Returns true if the given name is a processor; false otherwise
    def Dot.is_processor?(processor_name)
      true if @@processor_colours[processor_name]
    end
    
  end
  
end
