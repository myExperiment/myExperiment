# This is the module containing the Scufl model implementation i.e. the model structure/definition and all its internals.

module Scufl # :nodoc:
  
  # The model for a given Taverna 1 workflow.
  class Model
    # This returns a WorkflowDescription object.
    attr_reader :description
    
    # Retrieve the list of processors specific to the workflow.
    # Does not include those from nested workflows.
    attr_reader :processors
    
    # Retrieve the list of datalinks specific to the workflow.
    # Does not include those from nested workflows.
    attr_reader :links
    
    # Retrieve the list of sources specific to the workflow.
    # Does not include those from nested workflows.
    attr_reader :sources
    
    # Retrieve the list of sinks specific to the workflow.
    # Does not include those from nested workflows.
    attr_reader :sinks
    
    # Retrieve the list of coordinations specific to the workflow.
    # Does not include those from nested workflows.
    attr_reader :coordinations
    
    # The list of any dependencies that have been found inside the workflow.
    # Does not include those from nested workflows.
    attr_accessor :dependencies
    
    # Creates an empty model for a Taverna 1 workflow.
    def initialize
      @description = WorkflowDescription.new
      @processors = Array.new
      @links = Array.new
      @sources = Array.new
      @sinks = Array.new
      @coordinations = Array.new
    end
    
    # Retrieve ALL the beanshell processors WITHIN the given workflow model.
    def beanshells
      self.all_processors.select { |x| x.type == "beanshell" }
    end
    
    # Retrieve ALL processors of that are webservices WITHIN the model.
    def web_services
      self.all_processors.select { |x| x.type =~ /wsdl|soaplab|biomoby/i }
    end
    
    # Retrieve ALL local workers WITHIN the workflow
    def local_workers
      self.all_processors.select { |x| x.type =~ /local/i }
    end
    
    # Retrieve ALL processor objects WITHIN the given workflow model.
    def all_processors
      return get_processors(self, [])
    end
    
    
    # Retrieve ALL the links WITHIN the given workflow model.
    def all_links
      return get_links(self, [])
    end
    
    # Retrieve ALL the sinks(outputs) WITHIN the given workflow model.
    def all_sinks
      return get_sinks(self, [])
    end
    
    # Retrieve ALL the sources(inputs) WITHIN the given workflow model.    
    def all_sources
      return get_sources(self, [])
    end
    
    # For the given dataflow, return the beanshells and/or services which 
    # have direct links to or from the given processor.
    # == Usage
    #   my_processor = model.processor[0]
    #   linked_processors = model.get_processors_linked_to(my_processor)
    #   processors_feeding_into_my_processor = linked_processors.sources
    #   processors_feeding_from_my_processor = linked_processors.sinks    
    def get_processor_links(processor)
      return nil unless processor
      proc_links = ProcessorLinks.new
      
      # SOURCES
      sources = self.all_links.select { |x| x.sink =~ /#{processor.name}:.+/ }
      proc_links.sources = []

      # SINKS
      sinks = self.all_links.select { |x| x.source =~ /#{processor.name}:.+/ }
      proc_links.sinks = []
      temp_sinks = []
      sinks.each { |x| temp_sinks << x.sink }
      
      # Match links by port into format
      # my_port:name_of_link_im_linked_to:its_port
      sources.each do |connection|
        link = connection.sink
        connected_proc_name = link.split(":")[0]
        my_connection_port = link.split(":")[1]
        
        if my_connection_port
          source = my_connection_port << ":" << connection.source
          proc_links.sources << source if source.split(":").size == 3
        end
      end
      
      sinks.each do |connection|
        link = connection.source
        connected_proc_name = link.split(":")[0]
        my_connection_port = link.split(":")[1]
        
        if my_connection_port
          sink = my_connection_port << ":" << connection.sink
          proc_links.sinks << sink if sink.split(":").size == 3
        end
      end
      
      return proc_links
    end
  
    private
    
    def get_beanshells(given_model, beans_collected) # :nodoc:
      wf_procs = given_model.processors.select { |x| x.type == "workflow" }
      wf_procs.each { |x| get_beanshells(x.model, beans_collected) if x.model }
      
      bean_procs = given_model.processors.select { |b| b.type == "beanshell" }
      bean_procs.each { |a| beans_collected << a }
      
      return beans_collected
    end
    
    def get_processors(given_model, procs_collected) # :nodoc:
      wf_procs = given_model.processors.select { |x| x.type == "workflow" }
      wf_procs.each { |x| get_processors(x.model, procs_collected) if x.model }
      
      procs = given_model.processors
      procs.each { |a| procs_collected << a }
      
      return procs_collected
    end
    
    def get_links(given_model, links_collected) # :nodoc:
      wf_procs = given_model.processors.select { |x| x.type == "workflow" }
      wf_procs.each { |x| get_links(x.model, links_collected) if x.model }
      
      links = given_model.links
      links.each { |a| links_collected << a }
      
      return links_collected
    end
    
    def get_sinks(given_model, sinks_collected) # :nodoc:
      wf_procs = given_model.processors.select { |x| x.type == "workflow" }
      wf_procs.each { |x| get_sinks(x.model, sinks_collected) if x.model }
      
      sinks = given_model.sinks
      sinks.each { |a| sinks_collected << a }
      
      return sinks_collected
    end
    
    def get_sources(given_model, sources_collected) # :nodoc:
      wf_procs = given_model.processors.select { |x| x.type == "workflow" }
      wf_procs.each { |x| get_sources(x.model, sources_collected) if x.model }
      
      sources = given_model.sources
      sources.each { |a| sources_collected << a }
      
      return sources_collected
    end
  end
  
  
  
  # This is the (shim) object within the workflow.  This can be a beanshell,
  # a webservice, a workflow, etc...
  class Processor
    # A string containing name of the processor.
    attr_accessor :name 
    
    # A string containing the description of the processor if available.  
    # Returns nil otherwise.
    attr_accessor :description
    
    # A string for the type of processor, e.g. beanshell, workflow, webservice, etc...
    attr_accessor :type 
    
    # For processors that have type == "workflow", model is the the workflow 
    # definition.  For all other processor types, model is nil.
    attr_accessor :model
    
    # This only has a value in beanshell processors.  This is the actual script
    # embedded with the processor which does all the "work"
    attr_accessor :script
    
    # This is a list of inputs that the processor can take in.
    attr_accessor :inputs
    
    # This is a list of outputs that the processor can produce.
    attr_accessor :outputs
    
    # For processors of type "arbitrarywsdl", this is the URI to the location
    # of the wsdl file.
    attr_accessor :wsdl
    
    # For processors of type "arbitrarywsdl", this is the operation invoked.
    attr_accessor :wsdl_operation
    
    # For soaplab and biomoby services, this is the endpoint URI.
    attr_accessor :endpoint
    
    # Authority name for the biomoby service.
    attr_accessor :biomoby_authority_name

    # Service name for the biomoby service. This is not necessarily the same 
    # as the processors name.
    attr_accessor :biomoby_service_name
    
    # Category for the biomoby service.
    attr_accessor :biomoby_category

    # Value of a string constant
    attr_accessor :value
  end



  # This object is returned after invoking model.get_processor_links(processor)
  # .  The object contains two lists of processors.  Each element consists of: 
  # the input or output port the processor uses as a link, the name of the
  # processor being linked, and the port of the processor used for the linking,
  # all seperated by a colon (:) i.e. 
  #   my_port:name_of_processor:processor_port
  class ProcessorLinks
    # The processors whose output is fed as input into the processor used in
    # model.get_processors_linked_to(processor).
    attr_accessor :sources
    
    # A list of processors that are fed the output from the processor (used in
    # model.get_processors_linked_to(processor) ) as input.
    attr_accessor :sinks
  end
  

  
  # This contains basic descriptive information about the workflow model.
  class WorkflowDescription
    # The author of the workflow.
    attr_accessor :author
    
    # The name/title of the workflow.
    attr_accessor :title
    
    # A small piece of descriptive text for the workflow.
    attr_accessor :description
  end

  
  
  # This represents a connection between any of the following pair of entities:
  # {processor -> processor}, {workflow -> workflow}, {workflow -> processor}, 
  # and {processor -> workflow}.
  class Link
    # The name of the source (the starting point of the connection).
    attr_accessor :source
    
    # The name of the sink (the endpoint of the connection).
    attr_accessor :sink
  end



  # This is a representation of the 'Run after...' function in Taverna
  # where the selected processor or workflow is set to run after another.
  class Coordination
    # The name of the processor/workflow which is to run first.
    attr_accessor :controller
    
    # The name of the processor/workflow which is to run after the controller.
    attr_accessor :target
  end

  
  
  # This is the start node of a Link.  Each source has a name and a port
  # which is seperated by a colon; ":".
  # This is represented as "source of a processor:port_name".
  # A string that does not contain a colon can often be returned, signifiying
  # a workflow source as opposed to that of a processor.
  class Source
  	attr_accessor :name, :description
  end
  
  
  
  # This is the start node of a Link.  Each sink has a name and a port
  # which is seperated by a colon; ":".
  # This is represented as "sink of a processor:port_name".
  # A string that does not contain a colon can often be returned, signifiying
  # a workflow sink as opposed to that of a processor.
  class Sink
	  attr_accessor :name, :description
  end  	
  
end
