# myExperiment: lib/workflow_processors/galaxy.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'libxml'

module WorkflowProcessors

  class Galaxy < WorkflowProcessors::Interface

    Mime::Type.register "application/vnd.galaxy.workflow+json", :galaxy_workflow

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
      "JSON"
    end
    
    def self.mime_type
      "application/vnd.galaxy.workflow+json"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      ["ga"]
    end

    def self.default_file_extension
      "ga"
    end
    
    def self.can_determine_type_from_file?
      true
    end
    
    def self.recognised?(file)
      rec = file.readline.strip == '{' &&
            file.readline.strip == '"a_galaxy_workflow": "true",'
      file.rewind
      rec
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
    
    def self.show_download_section?
      true
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

    def get_title
      @model.title
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

      attr_accessor :title

      def self.parse(stream)
        doc = ActiveSupport::JSON.decode(stream)

        workflow = GalaxyLib::Workflow.new

        workflow.inputs      = []
        workflow.outputs     = []
        workflow.steps       = []
        workflow.connections = []

        workflow.title = doc["name"]

        # Parse the context of the workflow.
        doc["steps"].each_key.sort.each do |step_id| # Need to sort because the steps are backwards in the JSON
          step_element = doc["steps"][step_id]

          step = GalaxyLib::Step.new

          step.id          = step_id
          step.name        = step_element["name"]
          step.tool        = step_element["tool_id"] || "None"
          #step.description = nil   # No description present in JSON

          workflow.steps << step

          step_element["inputs"].each do |input_element|
            input = GalaxyLib::Input.new

            input.step_id     = step_id
            input.name        = input_element["name"]
            input.description = input_element["description"]

            workflow.inputs << input
          end

          step_element["outputs"].each do |output_element|
            output = GalaxyLib::Output.new

            output.step_id = step_id
            output.name    = output_element["name"]
            output.type    = output_element["type"]

            workflow.outputs << output
          end

          step_element["input_connections"].each do |conn_name, conn_element|
            connection = GalaxyLib::Connection.new

            connection.source_id     = conn_element["id"].to_s
            connection.source_output = conn_element["output_name"].to_s
            connection.sink_id       = step_id
            connection.sink_input    = conn_name

            workflow.connections << connection
          end
        end

        workflow
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

