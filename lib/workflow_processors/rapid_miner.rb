# myExperiment: lib/workflow_processors/rapid_miner.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

require "xml/libxml"
require "zip/zip"

module WorkflowProcessors

  class RapidMiner < WorkflowProcessors::Interface

    # Begin Class Methods

    # These:
    # - provide information about the Workflow Type supported by this processor,

    # MUST be unique across all processors
    def self.display_name
      "RapidMiner"
    end

    def self.display_data_format
      "XML"
    end

    def self.mime_type
      "application/vnd.rapidminer.rmp+zip"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "xml", "zip" ]
    end

    def self.can_determine_type_from_file?
      true
    end

    def self.recognised?(file)
      begin
        file.rewind
        rapid_miner_model = WorkflowProcessors::RapidMinerLib::Package.parse(file.read)
        file.rewind
        return !rapid_miner_model.nil?
      rescue
        puts $!
        return false
      end
    end

    def self.can_infer_metadata?
      true
    end

    def self.can_generate_preview_image?
      true
    end

    def self.can_generate_preview_svg?
      true
    end

    # End Class Methods


    # Begin Object Initializer

    def initialize(workflow_definition)
      super(workflow_definition)
      @rapid_miner_model = WorkflowProcessors::RapidMinerLib::Package.parse(workflow_definition)
    end

    # End Object Initializer


    # Begin Instance Methods

    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.

    def get_title
      return nil if @rapid_miner_model.nil?
      return nil if @rapid_miner_model.title.blank?

      @rapid_miner_model.title
    end

    def get_description
      @rapid_miner_model.description
    end

    def get_workflow_model_object
      return @rapid_miner_model
    end
    
    def get_preview_image
      @rapid_miner_model.image
    end

    def get_preview_svg
      @rapid_miner_model.svg
    end

    def get_workflow_model_input_ports

    end

    def get_search_terms
      ""
    end

    def get_components
      @rapid_miner_model.get_components
    end

    # End Instance Methods
  end


  module RapidMinerLib

    # A RapidMiner process.

    class Process

      # Operators of this process.
      attr_accessor :operators

      def self.parse(element)

        process = RapidMinerLib::Process.new
        process.operators = []

        element.find('operator').each do |operator|
          process.operators.push(RapidMinerLib::Operator.parse(operator))
        end

        process
      end

      def get_components
        element = XML::Node.new("process")

        operators.each do |operator|
          element << operator.get_components
        end

        element
      end

    end

    # A RapidMiner operator.

    class Operator

      # The name of this operator.
      attr_accessor :name

      # Sub processes of this operator.
      attr_accessor :processes

      def self.parse(element)
        operator = RapidMinerLib::Operator.new
        operator.processes = []

        name = element.find("@name")

        operator.name = name[0].value if name.length > 0

        element.find('process').each do |process|
          operator.processes.push(RapidMinerLib::Process.parse(process))
        end

        operator
      end
     
      def get_components
        element = XML::Node.new("operator")
        element["name"] = name

        processes.each do |process|
          element << process.get_components
        end

        element
      end

    end

    # A RapidMiner input.

    class Input
    
      # The location of the input.
      attr_accessor :location

      def get_components
        element = XML::Node.new("input")
        element["location"] = location
        element
      end
    end

    # A RapidMiner output.

    class Output
    
      # The location of the output.
      attr_accessor :location

      def get_components
        element = XML::Node.new("output")
        element["location"] = location
        element
      end
    end

    # This is the concept of the RapidMiner package that myExperiment deals with

    class Package 

      # Title of the workflow.
      attr_accessor :title

      # Description of the workflow.
      attr_accessor :description

      # Preview image of the workflow.
      attr_accessor :image

      # Preview SVG of the workflow.
      attr_accessor :svg

      # Inputs to the workflow.
      attr_accessor :inputs

      # Outputs of the workflow.
      attr_accessor :outputs

      # The root process of the workflow.
      attr_accessor :process

      def self.parse(stream)

        begin

          package = RapidMinerLib::Package.new

          Tempfile.open("rapid_miner", "tmp") do |zip_file|

            zip_file.write(stream)
            zip_file.close

            Zip::ZipFile.open(zip_file.path) do |zip|

              image = StringIO.new(zip.read("preview.png"))
              image.extend FileUpload
              image.original_filename = 'preview.png'

              svg = StringIO.new(zip.read("preview.svg"))
              svg.extend FileUpload
              svg.original_filename = 'preview.svg'

              process = LibXML::XML::Parser.string(zip.read("process.xml")).parse

              package.title       = "Temporary title"
              package.description = CGI.unescapeHTML(process.find("/process/operator/description/text()")[0].to_s)
              package.image       = image
              package.svg         = svg
              package.process     = RapidMinerLib::Process.parse(process.find("/process")[0])
              package.inputs      = []
              package.outputs     = []

              # Parse the context of the workflow.

              process.find("/process/context/input/location").each do |element|
                input = RapidMinerLib::Input.new
                input.location = element.find("text()")[0].to_s
                package.inputs.push(input)
              end

              process.find("/process/context/output/location").each do |element|
                output = RapidMinerLib::Output.new
                output.location = element.find("text()")[0].to_s
                package.outputs.push(output)
              end
            end
          end

          package
        rescue
          puts $!
          nil
        end
      end

      def get_components
        components = XML::Node.new("components")

        input_els  = XML::Node.new("inputs")
        output_els = XML::Node.new("outputs")

        inputs.each do |input|
          input_els << input.get_components
        end

        outputs.each do |output|
          output_els << output.get_components
        end
          
        components << process.get_components
        components << input_els
        components << output_els
      end
    end
  end
end

