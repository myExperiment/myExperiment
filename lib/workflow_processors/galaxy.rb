# myExperiment: lib/workflow_processors/galaxy.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors

  require 'libxml'
  
  class Galaxy < WorkflowProcessors::Interface

    Mime::Type.register "application/vnd.galaxy.workflow+xml", :galaxy_workflow

    # Begin Class Methods
    
    # These: 
    # - provide information about the Workflow Type supported by this processor,
    # - provide information about the processor's capabilites, and
    # - provide any general functionality.
    
    # MUST be unique across all processors
    def self.display_name 
      "Galaxy"
    end
    
    def self.display_data_format
      "XML"
    end
    
    def self.mime_type
      "application/vnd.galaxy.workflow+xml"
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
    
    def self.can_generate_preview_image?
      false
    end
    
    def self.can_generate_preview_svg?
      false
    end
    
    def self.show_download_section?
      false
    end

    def initialize(workflow_definition)
      super(workflow_definition)
      @model = WorkflowProcessors::GalaxyLib::Workflow.parse(workflow_definition)
    end
    
    def get_workflow_model_object
      @model
    end

    def get_components
      @model.get_components
    end

    def get_search_terms

      return "" if @model.nil?

      words = StringIO.new

      @model.steps.each do |step|
        words << " #{step.name} #{step.tool}"
      end

      @model.inputs.each do |input|
        words << " #{input.name} #{input.description}"
      end

      @model.outputs.each do |output|
        words << " #{output.name}"
      end

      words.rewind
      words.read
    end
  end

  module GalaxyLib

    class Workflow 

      # Inputs to the workflow.
      attr_accessor :inputs

      # Outputs of the workflow.
      attr_accessor :outputs

      # The steps of the workflow.
      attr_accessor :steps

      # The connections of the workflow.
      attr_accessor :connections

      def self.parse(stream)

        begin

          doc = LibXML::XML::Parser.string("<?xml version='1.0' encoding='UTF-8'?><content>#{stream}</content>").parse

          workflow = GalaxyLib::Workflow.new

          workflow.inputs      = []
          workflow.outputs     = []
          workflow.steps       = []
          workflow.connections = []

          # Parse the context of the workflow.

          doc.find("/content/steps/step/inputs/input").each do |input_element|

            input = GalaxyLib::Input.new

            input.step_id     = input_element.find("../../id/text()")[0].to_s
            input.name        = input_element.find("name/text()")[0].to_s
            input.description = CGI.unescapeHTML(input_element.find("description/text()")[0].to_s)

            workflow.inputs << input
          end

          doc.find("/content/steps/step/outputs/output").each do |output_element|

            output = GalaxyLib::Output.new

            output.step_id = output_element.find("../../id/text()")[0].to_s
            output.name    = output_element.find("name/text()")[0].to_s
            output.type    = output_element.find("type/text()")[0].to_s

            workflow.outputs << output
          end

          doc.find("/content/steps/step").each do |step_element|

            step = GalaxyLib::Step.new

            step.id          = step_element.find("id/text()")[0].to_s
            step.name        = step_element.find("name/text()")[0].to_s
            step.tool        = step_element.find("tool/text()")[0].to_s
            step.description = CGI.unescapeHTML(step_element.find("description/text()")[0].to_s)

            workflow.steps << step
          end

          doc.find("/content/connections/connection").each do |conn_element|

            conn = GalaxyLib::Connection.new

            conn.source_id     = conn_element.find("source_id/text()")[0].to_s
            conn.source_output = conn_element.find("source_output/text()")[0].to_s
            conn.sink_id       = conn_element.find("sink_id/text()")[0].to_s
            conn.sink_input    = conn_element.find("sink_input/text()")[0].to_s

            workflow.connections << conn
          end

          workflow
        rescue
          puts $!
          nil
        end
      end

      def get_components

        components = XML::Node.new("components")

        input_els      = XML::Node.new("inputs")
        output_els     = XML::Node.new("outputs")
        step_els       = XML::Node.new("steps")
        connection_els = XML::Node.new("connections")

        inputs.each do |input|
          input_els << input.get_components
        end

        outputs.each do |output|
          output_els << output.get_components
        end

        steps.each do |step|
          step_els << step.get_components
        end
          
        connections.each do |connection|
          connection_els << connection.get_components
        end
          
        components << input_els
        components << output_els
        components << step_els
        components << connection_els
      end
    end

    class Input

      attr_accessor :step_id
      attr_accessor :name
      attr_accessor :description

      def get_components

        components = XML::Node.new("input")

        components << (XML::Node.new("step-id") << step_id)
        components << (XML::Node.new("name") << name)
        components << (XML::Node.new("description") << description)

        components
      end

    end

    class Output

      attr_accessor :step_id
      attr_accessor :name
      attr_accessor :type

      def get_components

        components = XML::Node.new("output")

        components << (XML::Node.new("step-id") << step_id)
        components << (XML::Node.new("name") << name)
        components << (XML::Node.new("type") << type)

        components
      end

    end

    class Step
   
      attr_accessor :id   
      attr_accessor :name
      attr_accessor :tool
      attr_accessor :description

      def get_components

        components = XML::Node.new("step")

        components << (XML::Node.new("id") << id)
        components << (XML::Node.new("name") << name)
        components << (XML::Node.new("tool") << tool)
        components << (XML::Node.new("description") << description)

        components
      end
    end

    class Connection

      attr_accessor :source_id
      attr_accessor :source_output
      attr_accessor :sink_id
      attr_accessor :sink_input

      def get_components

        components = XML::Node.new("connection")

        components << (XML::Node.new("source-id")     << source_id)
        components << (XML::Node.new("source-output") << source_output)
        components << (XML::Node.new("sink-id")       << sink_id)
        components << (XML::Node.new("sink-input")    << sink_input)

        components
      end
    end
  end
end

