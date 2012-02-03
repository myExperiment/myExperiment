require "rexml/document"

module Scufl
  
  class Parser
    # Returns the model for the given t2flow_file.
    # The method accepts objects of classes File and String only.
    # ===Usage
    #   foo = ... # stuff to initialize foo here
    #   bar = Scufl::Parser.new.parse(foo)
    def parse(scufl)
      document = REXML::Document.new(scufl)
      
      root = document.root
      raise "Doesn't appear to be a workflow!" if root.name != "scufl"
      version = root.attribute('version').value
      
      create_model(root, version)
    end
    
    def create_model(element, version) # :nodoc:
      model = Model.new
      
      element.each_element('s:workflowdescription') { |description|  set_description(model, description, version)}
      element.each_element('s:processor')           { |processor|    add_processor(model, processor, version)}
      element.each_element('s:link')                { |link|         add_link(model, link, version)}
      element.each_element('s:source')              { |source|       add_source(model, source, version)}
      element.each_element('s:sink')                { |sink|         add_sink(model, sink, version)}
      element.each_element('s:coordination')        { |coordination| add_coordination(model, coordination, version)}
      
      return model   
    end
    
    def add_coordination(model, element, version) # :nodoc:
      coordination = Coordination.new
      
      element.each_element('s:condition') do |condition|
        condition.each_element('s:target') {|target| coordination.controller = target.text}
      end
      element.each_element('s:action') do |action|
        action.each_element('s:target') {|target| coordination.target = target.text}
      end
      
      model.coordinations.push coordination
    end
    
    def add_link(model, element, version) # :nodoc:
      link = Link.new
      
      if version == '0.1'
        element.each_element('s:input') { |input| link.sink = input.text}
        element.each_element('s:output') { |output| link.source = output.text}
      else
        source = element.attribute('source') 
        link.source = source.value if source
        
        sink = element.attribute('sink')
        link.sink = sink.value if sink
      end
      
      model.links.push link
    end
    
    def add_source(model, element, version) # :nodoc:
      source = Source.new
      
      if version == '0.1'
        name = element.text
        source.name = name.value if name
      else
        name = element.attribute('name')
        source.name = name.value if name
        element.each_element('s:metadata') { |metadata|
          metadata.each_element('s:description') {|description| source.description = description.text}			
        }
      end
      
      model.sources.push source
    end
    
    def add_sink(model, element, version) # :nodoc:
      sink = Sink.new
      
      if version == '0.1'
        name = element.text
        sink.name = name.value if name
      else
        name = element.attribute('name')
        sink.name = name.value if name
        element.each_element('s:metadata') { |metadata|
          metadata.each_element('s:description') {|description| sink.description = description.text}			
        }
      end
      
      model.sinks.push sink
    end
    
    def add_processor(model, element, version) # :nodoc:
      processor = Processor.new
      
      name = element.attribute('name')
      processor.name = name.value if name
      
      element.each_element() do |e|
        case e.name
          when 'description'
            processor.description = e.text
          when 'arbitrarywsdl'
            processor.type = e.name
            e.each_element do |wsdl|
              processor.wsdl = wsdl.text if wsdl.name == 'wsdl'
              processor.wsdl_operation = wsdl.text if wsdl.name == 'operation'
            end
          when 'soaplabwsdl'
            processor.type = e.name
            processor.endpoint = e.text
          when 'biomobywsdl'
            processor.type = e.name
            e.each_element do |wsdl|
              case wsdl.name
                when /endpoint/i
                  processor.endpoint = wsdl.text
                when /servicename/i
                  processor.biomoby_service_name = wsdl.text
                when /authorityname/i
                  processor.biomoby_authority_name = wsdl.text
                when "category"
                  processor.biomoby_category = wsdl.text
              end
            end
          when'beanshell'
            processor.type = e.name
            e.each_element do |bean|
              case bean.name
                when "scriptvalue"
                  processor.script = bean.text
                when "beanshellinputlist"
                  bean.each_element do |input|
                    if input.name == "beanshellinput"
                      processor.inputs = [] if processor.inputs.nil?
                      processor.inputs << input.text
                    end # if
                  end # bean.each_element
                when "beanshelloutputlist"
                  bean.each_element do |output|
                    if output.name == "beanshelloutput"
                      processor.outputs = [] if processor.outputs.nil?
                      processor.outputs << output.text
                    end # if
                  end # bean.each_element
                when "dependencies"
                  bean.each_element do |dep|
                    model.dependencies = [] if model.dependencies.nil?
                    model.dependencies << dep.text unless dep.text =~ /^\s*$/
                  end # bean.each_element
                end # case bean.name
              end # e.each_element
            when 'mergemode'
            when 'defaults'
            when 'iterationstrategy'
            when 'stringconstant'
              processor.type = e.name
              processor.value = e.text
            else
            if Dot.is_processor? e.name
              processor.type = e.name
              if processor.type == 'workflow'
                e.each_element('s:scufl') {|e| processor.model = create_model(e, version)}
              end
            end
          end
        end
      
      model.processors.push processor
      end
    
    def set_description(model, element, version) # :nodoc:
      author = element.attribute('author')
      title = element.attribute('title')
      
      model.description.author = author.value if author
      model.description.title = title.value if title
      model.description.description = element.text
    end
    
  end
  
end
