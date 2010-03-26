require "libxml"

module T2Flow
  
  class Parser
    # Returns the model for the given t2flow_file.
    # The method accepts objects of classes File, StringIO and String only.
    # ===Usage
    #   foo = ... # stuff to initialize foo here
    #   bar = T2Flow::Parser.new.parse(foo)
    def parse(t2flow)
      case t2flow.class.to_s
        when /^string$/i
          document = LibXML::XML::Parser.string(t2flow).parse 
        when /^stringio|file$/i
          t2flow.rewind
          document = LibXML::XML::Parser.string(t2flow.read).parse 
        else 
          raise "Error parsing file."
      end

      root = document.root
      raise "Doesn't appear to be a workflow!" if root.name != "workflow"
      version = root["version"]
      
      create_model(root, version)
    end
    
    def create_model(element, version) # :nodoc:
      model = Model.new
      
      local_depends = element.find("//localDependencies")
      if local_depends
        local_depends.each do |dependency|
          dependency.each do |dep| 
            model.dependencies = [] if model.dependencies.nil?
            model.dependencies << dep.content unless dep.content =~ /^\s*$/
          end
        end
        model.dependencies.uniq! if model.dependencies
      end
    
      element.each do |dataflow|
        dataflow_obj = Dataflow.new
        dataflow_obj.dataflow_id = dataflow["id"]
        dataflow_obj.role = dataflow["role"]
        
        dataflow.each do |elt|
          case elt.name
            when "name"
              dataflow_obj.annotations.name = elt.content
            when "inputPorts"
              elt.each { |port| add_source(dataflow_obj, port) }
            when "outputPorts"
              elt.each { |port| add_sink(dataflow_obj, port) }
            when "processors"
              elt.each { |proc| add_processor(dataflow_obj, proc) }
            when "datalinks"
              elt.each { |link| add_link(dataflow_obj, link) }
            when "conditions"
              elt.each { |coord| add_coordination(dataflow_obj, coord) }
            when "annotations"
              elt.each { |ann| add_annotation(dataflow_obj, ann) }
          end # case elt.name
        end # dataflow.each
        
        model.dataflows << dataflow_obj
      end # element.each
      
      temp = model.processors.select { |x| x.type == "workflow" }
      temp.each do |proc|
        df = model.dataflow(proc.dataflow_id)
        df.annotations.name = proc.name
      end
      
      return model   
    end
    
    def add_source(dataflow, port) # :nodoc:
      source = Source.new
      
      port.each do |elt|
        case elt.name
          when "name": source.name = elt.content
          when "annotations"
            elt.each do |ann|
              node = LibXML::XML::Parser.string("#{ann}").parse
              content_node = node.find_first("//annotationBean")
              content = content_node.child.next.content
      
              case content_node["class"]
                when /freetextdescription/i
                  source.descriptions = [] unless source.descriptions
                  source.descriptions << content
                when /examplevalue/i
                  source.example_values = [] unless source.example_values
                  source.example_values << content
              end # case
            end # elt.each
        end # case
      end # port.each
      
      dataflow.sources << source
    end
    
    def add_sink(dataflow, port) # :nodoc:
      sink = Sink.new
      
      port.each do |elt|
        case elt.name
          when "name": sink.name = elt.content
          when "annotations"
            elt.each do |ann|
              node = LibXML::XML::Parser.string("#{ann}").parse
              content_node = node.find_first("//annotationBean")
              content = content_node.child.next.content
      
              case content_node["class"]
                when /freetextdescription/i
                  sink.descriptions = [] unless sink.descriptions
                  sink.descriptions << content
                when /examplevalue/i
                  sink.example_values = [] unless sink.example_values
                  sink.example_values << content
              end # case
            end # elt.each
        end # case
      end # port.each
      
      dataflow.sinks << sink
    end
    
    def add_processor(dataflow, element) # :nodoc:
      processor = Processor.new
      
      temp_inputs = []
      temp_outputs = []
      
      element.each do |elt|
        case elt.name
          when "name"
            processor.name = elt.content
          when /inputports/i # ports from services
            elt.each { |port| 
              port.each { |x| temp_inputs << x.content if x.name=="name" }
            }
          when /outputports/i # ports from services
            elt.each { |port| 
              port.each { |x| temp_outputs << x.content if x.name=="name" }
            }
          when "activities" # a processor can only have one kind of activity
            activity = elt.child
            activity.each do |node|
              if node.name == "configBean"
                  activity_node = node.child
                  
                  if node["encoding"] == "dataflow"
                    processor.dataflow_id = activity_node["ref"]
                    processor.type = "workflow"
                  else
                    processor.type = (activity_node.name =~ /martquery/i ?
                        "biomart" : activity_node.name.split(".")[-2])
                    
                    activity_node.each do |value_node|
                      case value_node.name
                        when "wsdl"
                          processor.wsdl = value_node.content
                        when "operation"
                          processor.wsdl_operation = value_node.content
                        when /endpoint/i
                          processor.endpoint = value_node.content
                        when /servicename/i
                          processor.biomoby_service_name = value_node.content
                        when /authorityname/i
                          processor.biomoby_authority_name = value_node.content
                        when "category"
                          processor.biomoby_category = value_node.content
                        when "script"
                          processor.script = value_node.content
                        when "value"
                          processor.value = value_node.content
                        when "inputs" # ALL ports present in beanshell
                          value_node.each { |input| 
                            input.each { |x| 
                              processor.inputs = [] if processor.inputs.nil?
                              processor.inputs << x.content if x.name == "name" 
                            }
                          }
                        when "outputs" # ALL ports present in beanshell
                          value_node.each { |output| 
                            output.each { |x| 
                              processor.outputs = [] if processor.outputs.nil?
                              processor.outputs << x.content if x.name == "name" 
                            }
                          }
                      end # case value_node.name
                    end # activity_node.each
                  end # if else node["encoding"] == "dataflow"
              end # if node.name == "configBean"
            end # activity.each
        end # case elt.name
      end # element.each
      
      processor.inputs = temp_inputs if processor.inputs.nil? && !temp_inputs.empty?
      processor.outputs = temp_outputs if processor.outputs.nil? && !temp_outputs.empty?
      dataflow.processors << processor
    end
    
    def add_link(dataflow, link) # :nodoc:
      datalink = Datalink.new
      
      link.each do |sink_source|
        case sink_source.name
          when "sink"
            datalink.sink = sink_source.first.content
            datalink.sink += ":" + sink_source.last.content if sink_source["type"] == "processor"
          when "source"
            datalink.source = sink_source.first.content
            datalink.source += ":" + sink_source.last.content if sink_source["type"] == "processor"
        end
      end
      
      dataflow.datalinks << datalink
    end
    
    def add_coordination(dataflow, condition) # :nodoc:
      coordination = Coordination.new
      
      coordination.control = condition["control"]
      coordination.target = condition["target"]
      
      dataflow.coordinations << coordination
    end
    
    def add_annotation(dataflow, annotation) # :nodoc:
      node = LibXML::XML::Parser.string("#{annotation}").parse
      content_node = node.find_first("//annotationBean")
      content = content_node.child.next.content
      
      case content_node["class"]
        when /freetextdescription/i
          dataflow.annotations.descriptions = [] unless dataflow.annotations.descriptions
          dataflow.annotations.descriptions << content
        when /descriptivetitle/i
          dataflow.annotations.titles = [] unless dataflow.annotations.titles
          dataflow.annotations.titles << content
        when /author/i
          dataflow.annotations.authors = [] unless dataflow.annotations.authors
          dataflow.annotations.authors << content
        end # case
    end
    
  end
  
end
