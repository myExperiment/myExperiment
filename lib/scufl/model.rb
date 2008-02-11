module Scufl
  
  class Model

    attr_reader :description, :processors, :links, :sources, :sinks, :coordinations
    
    def initialize
      @description = WorkflowDescription.new
      @processors = Array.new
      @links = Array.new
      @sources = Array.new
      @sinks = Array.new
      @coordinations = Array.new
    end
    
  end
  
  class Processor
    attr_accessor :name, :description, :type, :model
  end
  
  class WorkflowDescription
    attr_accessor :author, :title, :description
  end
  
  class Link
    attr_accessor :source, :sink
  end

  class Coordination
    attr_accessor :controller, :target
  end
  
  class Source
  	attr_accessor :name, :description
  end
  
  class Sink
	attr_accessor :name, :description
  end  	
  
end
