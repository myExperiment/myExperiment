# myExperiment: lib/workflow_processors/kepler.rb
#
# Copyright (c) 2017 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors

  class Kepler < WorkflowProcessors::Interface

    # Begin Class Methods

    # These:
    # - provide information about the Workflow Type supported by this processor,

    # MUST be unique across all processors
    def self.display_name
      "Kepler"
    end

    def self.display_data_format
      "XML"
    end

    def self.mime_type
      "application/octet-stream"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "xml", "kar" ]
    end

    def self.default_file_extension
      "xml"
    end

    def self.can_determine_type_from_file?
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

    # End Class Methods


    # Begin Object Initializer

    def initialize(workflow_definition)
      nil
    end

  end
end
