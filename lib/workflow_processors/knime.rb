# myExperiment: lib/workflow_processors/knime.rb
#
# Copyright (c) 2016 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors

  class Knime < WorkflowProcessors::Interface

    # Begin Class Methods

    # These:
    # - provide information about the Workflow Type supported by this processor,

    # MUST be unique across all processors
    def self.display_name
      "KNIME"
    end

    def self.display_data_format
      "ZIP"
    end

    def self.mime_type
      "application/zip"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "zip" ]
    end

    def self.default_file_extension
      "zip"
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
