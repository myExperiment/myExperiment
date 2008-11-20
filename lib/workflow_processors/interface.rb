# myExperiment: lib/workflow_processors/interface.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

# Defines an interface that all workflow type processors need to adhere to.
module WorkflowProcessors
  class Interface
    
    # Begin Class Methods
    
    # These: 
    # - provide information about the Workflow Type supported by this processor,
    # - provide information about the processor's capabilites, and
    # - provide any general functionality.
    
    # MUST be unique across all processors
    def self.display_name
      ""
    end
    
    # MUST be unique across all processors
    def self.content_type
      ""
    end
    
    def self.display_data_format
      ""
    end
    
    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      []
    end
    
    def self.can_determine_type_from_file?
      false
    end
    
    def self.recognised?(file)
      false
    end
    
    def self.can_infer_metadata?
      false
    end
    
    def self.can_generate_preview?
      false
    end
    
    # End Class Methods


    # Begin Object Initializer

    def initialize(workflow_definition)
      @workflow_definition = workflow_definition
    end

    # End Object Initializer
    
    
    # Begin Instance Methods
    
    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.
    
    def get_title
      nil
    end
    
    def get_description
      nil
    end
    
    def get_preview_images
      nil
    end
    
    def get_workflow_model_object
      nil
    end
    
    def get_workflow_model_input_ports
      
    end
    
    def get_search_terms
      ""
    end

    # End Instance Methods
    
  end
end
