# myExperiment: lib/workflow_processors/bioextract_processosr.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors

  class BioExtract < WorkflowProcessors::Interface

    # Begin Class Methods

    # These:
    # - provide information about the Workflow Type supported by this processor,

    # MUST be unique across all processors
    def self.display_name
      "BioExtract Server"
    end

    def self.display_data_format
      "XML"
    end

    def self.mime_type
      "application/xml"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "xml" ]
    end

    def self.can_determine_type_from_file?
      true
    end

    def self.recognised?(file)
      begin
        file.rewind
        bioextract_model = WorkflowProcessors::BioExtractLib::Parser.parse(file.read)
        file.rewind
        return !bioextract_model.nil?
      rescue
        puts $!
        return false
      end
    end

    def self.can_infer_metadata?
      true
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
      super(workflow_definition)
      @bioextract_model = WorkflowProcessors::BioExtractLib::Parser.parse(workflow_definition)
    end

    # End Object Initializer


    # Begin Instance Methods

    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.

    def get_title
      return nil if @bioextract_model.nil?
      return (@bioextract_model.title.blank? ? "[untitled]" : @bioextract_model.title)
    end

    def get_description
      return nil if @bioextract_model.nil?
      return @bioextract_model.description
    end

    def get_workflow_model_object
      return @bioextract_model
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
      XML::Node.new("components")
    end

    # End Instance Methods
  end


  module BioExtractLib

    class Model
      # The author of the workflow.
      attr_accessor :author

      # The name/title of the workflow.
      attr_accessor :title

      # A small piece of descriptive text for the workflow.
      attr_accessor :description

      #link used to execute the workflow
      attr_accessor :external_exe_link

    end
    
    module Parser

      require "rexml/document"
   
      def self.parse(xml)
        document = REXML::Document.new(xml)

        root = document.root
        raise "Doesn't appear to be a workflow!" if root.name != "bioextract"
        version = root.attribute('version').value
        baseURL = root.attribute('s').value

        create_model(root, version, baseURL)
      end
      
      def self.create_model(element, version, baseURL) # :nodoc:
        model = BioExtractLib::Model.new      
        element.each_element('s:workflowdescription') { |description| set_description(model, description, version, baseURL)}
        return model
      end
      
   
      def self.set_description(model, element, version, baseURL) # :nodoc:

        author = element.attribute('author')
        title = element.attribute('title')
        uid = element.attribute('uid')
        description = element.attribute('description')

        model.author = author.value if author
        model.title = title.value if title
        model.description = description.value if description
        model.external_exe_link = baseURL+"/ExternalWorkflowImport?importId="+uid.value if uid
      end
      
    end

  end
  
end
