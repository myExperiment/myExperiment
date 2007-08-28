require "rexml/document"

module Scufl
  
  class Parser
    
    def parse(scufl)
      document = REXML::Document.new(scufl)
      
      root = document.root
      raise "Doesn't appear to be a workflow!" if root.name != "scufl"
      version = root.attribute('version').value
      
      create_model(root, version)
    end
    
    def create_model(element, version)
      model = Model.new
      
      element.each_element('s:workflowdescription') { |description|  set_description(model, description, version)}
      element.each_element('s:processor')           { |processor|    add_processor(model, processor, version)}
      element.each_element('s:link')                { |link|         add_link(model, link, version)}
      element.each_element('s:source')              { |source|       add_source(model, source, version)}
      element.each_element('s:sink')                { |sink|         add_sink(model, sink, version)}
      element.each_element('s:coordination')        { |coordination| add_coordination(model, coordination, version)}
      
      return model   
    end
    
    def add_coordination(model, element, version)
      coordination = Coordination.new
      
      element.each_element('s:condition') do |condition|
        condition.each_element('s:target') {|target| coordination.controller = target.text}
      end
      element.each_element('s:action') do |action|
        action.each_element('s:target') {|target| coordination.target = target.text}
      end
      
      model.coordinations.push coordination
    end
    
    def add_link(model, element, version)
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
    
    def add_source(model, element, version)
      if version == '0.1'
        name = element.text
        model.sources.push name.strip if name
      else
        name = element.attribute('name')
        model.sources.push name.value if name
      end
    end
    
    def add_sink(model, element, version)
      if version == '0.1'
        name = element.text
        model.sinks.push name.strip if name
      else
        name = element.attribute('name')
        model.sinks.push name.value if name
      end
    end
    
    def add_processor(model, element, version)
      processor = Processor.new
      
      name = element.attribute('name')
      processor.name = name.value if name
      
      element.each_element() do |e|
        case e.name
        when 'description'
          processor.description = e.text
        when 'mergemode'
        when 'defaults'
        when 'iterationstrategy'
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
    
    def set_description(model, element, version)      
      author = element.attribute('author')
      title = element.attribute('title')
      
      model.description.author = author.value if author
      model.description.title = title.value if title
      model.description.description = element.text
    end
    
  end
  
end
