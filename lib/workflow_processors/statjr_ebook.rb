# myExperiment: lib/workflow_processors/bioextract_processosr.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors

  class StatjrEbook < WorkflowProcessors::Interface

    # Begin Class Methods

    # These:
    # - provide information about the Workflow Type supported by this processor,

    # MUST be unique across all processors
    def self.display_name
      "StatJR eBook"
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

    def self.can_determine_type_from_file?
      true
    end

    def self.recognised?(file)
      begin
        file.rewind
        deep_model = WorkflowProcessors::StatjrEbookLib::Parser.parse(file.read)
        file.rewind
#        Rails.logger.info "deep model: #{deep_model.title}" 
        return !deep_model.nil?
      rescue
        Rails.logger.info $!
        return false
      end
    end

    def self.can_infer_metadata?
      ##return true
      return false
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
      @deep_model = WorkflowProcessors::StatjrEbookLib::Parser.parse(workflow_definition)
    end

    # End Object Initializer


    # Begin Instance Methods

    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.

    def get_title
      return nil if @deep_model.nil?
      return (@deep_model.title.blank? ? "[untitled]" : @deep_model.title)
    end

    def get_description
      return nil if @deep_model.nil?
      return @deep_model.description
    end

    def get_workflow_model_object
      return @deep_model
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

    # End Instance Methods
  end


  module StatjrEbookLib

    class Model
      # The author of the workflow.
      attr_accessor :author

      # The name/title of the workflow.
      attr_accessor :title

      # A small piece of descriptive text for the workflow.
      attr_accessor :description

    end

    module Parser

      require "zip/zip"
      ##require 'rdf'
      ##require 'rdf/raptor'

      def self.parse(stream)
        begin
          Tempfile.open("deep", "tmp") do |zip_file|
            zip_file.write(stream)
            zip_file.close

            Zip::ZipFile.open(zip_file.path) do |zip|
              ebookdef = zip.read("ebookdef.ttl")
              ##graph = RDF::Graph.new()
              ##reader = RDF::Reader.for(:turtle).new(ebookdef)
              ##graph << reader
              ##ns_ebook = RDF::Vocabulary.new("http://purl.org/net/deep/ns#")
              ##ns_dcterms = RDF::Vocabulary.new("http://purl.org/dc/terms/")
              ##query = RDF::Query.new do
              ##  pattern [:ebook, RDF.type, ns_ebook.EbookFile]
              ##  pattern [:ebook, ns_dcterms.title, :title]
              ##end
              ebook = nil
              title = nil
              desc = nil
              ##query.execute(graph).each do |solution|
              ##  ebook = solution.ebook
              ##  title = solution.title.to_s
              ##end

              ##return nil unless ebook

              ##query = RDF::Query.new do
              ##  pattern [ebook, ns_dcterms.description, :desc]
              ##end
              ##query.execute(graph).each do |solution|
              ##  desc = solution.desc.to_s
              ##end
              return create_model(ebook, title, desc)
            end
          end
        rescue
          Rails.logger.info $!
          nil
        end
      end
      def self.create_model(ebook, title, description) # :nodoc:
        model = StatjrEbookLib::Model.new
        model.title = title
        model.description = description
        return model
      end

    end

  end

end
