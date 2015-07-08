# myExperiment: lib/workflow_processors/systo_model.rb
#
# Copyright (c) 2015 University of Manchester and the University of Southampton.
# See license.txt for details.

require "zip/zip"
require 'rdf'
require 'rdf/turtle'

module WorkflowProcessors

  class SystoModel < WorkflowProcessors::Interface

    # Begin Class Methods

    # These:
    # - provide information about the Workflow Type supported by this processor,

    # MUST be unique across all processors
    def self.display_name
      "Systo"
    end

    def self.display_data_format
      "JSON"
    end

    def self.mime_type
      "application/json"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "json" ]
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

    def self.can_generate_preview_image?
      false
    end

    def self.can_generate_preview_svg?
      false
    end

    def initialize(workflow_definition)
      super(workflow_definition)
      @model = JSON.parse(workflow_definition)
    end

    def get_title
      @model["meta"]["label"] if @model["meta"]
    end

    def get_description
      nil
    end

    def get_workflow_model_object
      @model
    end
    
    def get_preview_image
      nil
    end

    def get_preview_svg
      nil
    end

    def get_workflow_model_input_ports

    end

    def get_search_terms
      ""
    end

    def get_components
    end

  end

end
