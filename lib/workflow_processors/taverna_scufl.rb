# myExperiment: lib/workflow_processors/taverna_scufl.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors
  
  require 'scufl/model'
  require 'scufl/parser'
  require 'scufl/dot'
  
  require 'file_upload'

  class TavernaScufl < WorkflowProcessors::Interface
    # Register Taverna MIME Types
    Mime::Type.register "application/vnd.taverna.rest+xml", :taverna_rest
    Mime::Type.register "application/vnd.taverna.scufl+xml", :taverna_scufl
    Mime::Type.register "application/vnd.taverna.baclava+xml", :taverna_baclava
    Mime::Type.register "application/vnd.taverna.report+xml", :taverna_report
    
    # Begin Class Methods
    
    # These: 
    # - provide information about the Workflow Type supported by this processor,
    # - provide information about the processor's capabilites, and
    # - provide any general functionality.
  
    # MUST be unique across all processors
    def self.display_name 
      "Taverna 1"
    end
    
    # MUST be unique across all processors
    def self.content_type
      "application/vnd.taverna.scufl+xml"
    end
    
    def self.display_data_format
      "SCUFL"
    end
    
    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "xml" ]
    end
    
    def self.recognised?(file)
      # Check that the first KB of the file contains the <scufl> tag.  
      scufl_first_k = file.read(1024)
      file.rewind
      
      return scufl_first_k =~ %r{<[^<>]*scufl[^<>]*>}
    end
    
    def self.can_infer_metadata?
      true
    end
    
    def self.can_generate_preview?
      true
    end
    
    # End Class Methods
    
    
    # Begin Object Initializer

    def initialize(workflow_definition)
      super(workflow_definition)
      @scufl_model = Scufl::Parser.new.parse(workflow_definition)
    end

    # End Object Initializer
    
    
    # Begin Instance Methods
    
    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.
    
    def get_title
      return nil if @scufl_model.nil?
      return (@scufl_model.description.title.blank? ? "[untitled]" : @scufl_model.description.title)
    end
    
    def get_description
      return nil if @scufl_model.nil?
      return @scufl_model.description.description
    end
    
    def get_preview_images
      return nil if @scufl_model.nil?
      
      if RUBY_PLATFORM =~ /mswin32/
        return nil
      else
        title = @scufl_model.description.title.blank? ? "untitled" : @scufl_model.description.title
        filename = title.gsub(/[^\w\.\-]/,'_').downcase
        
        i = Tempfile.new("image")
        Scufl::Dot.new.write_dot(i, @scufl_model)
        i.close(false)
        img = StringIO.new(`dot -Tpng #{i.path}`)
        svg = StringIO.new(`dot -Tsvg #{i.path}`)
        img.extend FileUpload
        img.original_filename = "#{filename}.png"
        img.content_type = "image/png"
        svg.extend FileUpload
        svg.original_filename = "#{filename}.svg"
        svg.content_type = "image/svg+xml"
        return [img, svg]
      end
    end
    
    def get_workflow_model_object
      @scufl_model
    end
    
    def get_workflow_model_input_ports
      return (@scufl_model.nil? ? nil : @scufl_model.sources)
    end
    
    # End Instance Methods
  end
end