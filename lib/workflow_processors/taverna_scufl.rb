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
    
    def self.display_data_format
      "SCUFL"
    end
    
    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "xml", "scufl" ]
    end
    
    def self.can_determine_type_from_file?
      true
    end
    
    def self.recognised?(file)
      begin
        scufl_model = Scufl::Parser.new.parse(file.read)
        file.rewind
        return !scufl_model.nil?
      rescue
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
    
    def get_preview_image
      return nil if @scufl_model.nil? || RUBY_PLATFORM =~ /mswin32/

      title = @scufl_model.description.title.blank? ? "untitled" : @scufl_model.description.title
      filename = title.gsub(/[^\w\.\-]/,'_').downcase
      
      i = Tempfile.new("image")
      Scufl::Dot.new.write_dot(i, @scufl_model)
      i.close(false)

      img = StringIO.new(`dot -Tpng #{i.path}`)
      img.extend FileUpload
      img.original_filename = "#{filename}.png"
      img.content_type = "image/png"

      img
    end

    def get_preview_svg
      return nil if @scufl_model.nil? || RUBY_PLATFORM =~ /mswin32/

      title = @scufl_model.description.title.blank? ? "untitled" : @scufl_model.description.title
      filename = title.gsub(/[^\w\.\-]/,'_').downcase
      
      i = Tempfile.new("image")
      Scufl::Dot.new.write_dot(i, @scufl_model)
      i.close(false)

      svg = StringIO.new(`dot -Tsvg #{i.path}`)
      svg.extend FileUpload
      svg.original_filename = "#{filename}.svg"
      svg.content_type = "image/svg+xml"

      svg
    end

    def get_workflow_model_object
      @scufl_model
    end
    
    def get_workflow_model_input_ports
      return (@scufl_model.nil? ? nil : @scufl_model.sources)
    end
    
    def get_search_terms

      def get_scufl_metadata(model)

        words = StringIO.new

        model.sources.each do |source|
          words << " #{source.name}"        if source.name
          words << " #{source.description}" if source.description
        end

        model.sinks.each do |sink|
          words << " #{sink.name}"        if sink.name
          words << " #{sink.description}" if sink.description
        end

        model.processors.each do |processor|
          words << " #{processor.name}"                if processor.name
          words << " #{processor.description}"         if processor.description
          words << get_scufl_metadata(processor.model) if processor.model
        end

        words.rewind
        words.read
      end

      return "" if @scufl_model.nil?

      return get_scufl_metadata(@scufl_model)
    end

    def get_components

      model = @scufl_model

      components = XML::Node.new('components')

      sources    = XML::Node.new('sources')
      sinks      = XML::Node.new('sinks')
      processors = XML::Node.new('processors')
      links      = XML::Node.new('links')

      model.sources.each do |source|
        el = XML::Node.new('source')

        el << (XML::Node.new('name')        << source.name)        if source.name
        el << (XML::Node.new('description') << source.description) if source.description

        sources << el
      end

      model.sinks.each do |sink|
        el = XML::Node.new('sink')

        el << (XML::Node.new('name')        << sink.name)        if sink.name
        el << (XML::Node.new('description') << sink.description) if sink.description

        sinks << el
      end

      model.processors.each do |processor|
        el = XML::Node.new('processor')

        el << (XML::Node.new('name')        << processor.name)        if processor.name
        el << (XML::Node.new('description') << processor.description) if processor.description
        el << (XML::Node.new('type')        << processor.type)        if processor.type

        processors << el
      end

      model.links.each do |link|
        el = XML::Node.new('link')

        sink_bits   = link.sink.split(':')
        source_bits = link.source.split(':')

        sink   = XML::Node.new('sink')
        source = XML::Node.new('source')

        sink << (XML::Node.new('node') << sink_bits[0]) if sink_bits[0]
        sink << (XML::Node.new('port') << sink_bits[1]) if sink_bits[1]

        source << (XML::Node.new('node') << source_bits[0]) if source_bits[0]
        source << (XML::Node.new('port') << source_bits[1]) if source_bits[1]

        el << sink
        el << source

        links << el
      end

      components << sources
      components << sinks
      components << processors
      components << links

      components
    end

    # End Instance Methods
  end
end
