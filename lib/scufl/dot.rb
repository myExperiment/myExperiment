module Scufl
  
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
    
    def initialize
      @port_style = 'none' # 'all', 'bound' or 'none'
    end
    
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
    
    def write_workflow(stream, model, prefix="", name="", depth=0)
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
      model.coordinations.each {|coordination| write_coordination(stream, coordination, prefix)}
      if name != ""
        stream.puts '}'
      end
    end
    
    def write_processor(stream, processor, prefix, depth)
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
    
    def write_source_cluster(stream, sources, prefix)
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
    
    def write_source(stream, source, prefix)
      stream.puts " \"#{prefix}WORKFLOWINTERNALSOURCE_#{source}\" ["
      stream.puts '   shape="box",'
      stream.puts "   label=\"#{source}\""
      stream.puts '   width="0",'
      stream.puts '   height="0",'
      stream.puts '   fillcolor="skyblue"'
      stream.puts ' ]' 
    end
    
    def write_sink_cluster(stream, sinks, prefix)
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
    
    def write_sink(stream, sink, prefix)
      stream.puts " \"#{prefix}WORKFLOWINTERNALSINK_#{sink}\" ["
      stream.puts '   shape="box",'
      stream.puts "   label=\"#{sink}\""
      stream.puts '   width="0",'
      stream.puts '   height="0",'
      stream.puts '   fillcolor="lightsteelblue2"'
      stream.puts ' ]'     
    end
    
    def write_link(stream, link, model, prefix)
      if model.sources.include? link.source
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
      if model.sinks.include? link.sink
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
    
    def write_coordination(stream, coordination, prefix)
      stream.puts " \"#{prefix}#{coordination.controller}\"->\"#{prefix}#{coordination.target}\" ["
      stream.puts '  color="gray",'
      stream.puts '  arrowhead="odot",'
      stream.puts '  arrowtail="none"'
      stream.puts ' ];'
    end
    
    def get_colour(processor_name)
      colour = @@processor_colours[processor_name]
      if colour
        colour
      else 
        'white'
      end  
    end
    
    def Dot.is_processor?(processor_name)
      true if @@processor_colours[processor_name]
    end
    
  end
  
end
