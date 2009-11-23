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

      def build(name, text = nil, &blk)
        node = XML::Node.new(name)
        node << text if text
        yield(node) if blk
        node
      end

      def aux(model, tag)

        build(tag) do |element|

          element << build('sources') do |sources_element|
            model.sources.each do |source|
              sources_element << build('source') do |source_element|
                source_element << build('name',        source.name)        if source.name
                source_element << build('description', source.description) if source.description
              end
            end
          end

          element << build('sinks') do |sinks_element|
            model.sinks.each do |sink|
              sinks_element << build('sink') do |sink_element|
                sink_element << build('name',        sink.name)        if sink.name
                sink_element << build('description', sink.description) if sink.description
              end
            end
          end

          element << build('processors') do |processors_element|

            model.processors.each do |processor|

              processors_element << build('processor') do |processor_element|

                processor_element << build('name',                   processor.name)                   if processor.name
                processor_element << build('description',            processor.description)            if processor.description
                processor_element << build('type',                   processor.type)                   if processor.type
                processor_element << build('script',                 processor.script)                 if processor.script
                processor_element << build('wsdl',                   processor.wsdl)                   if processor.wsdl
                processor_element << build('wsdl-operation',         processor.wsdl_operation)         if processor.wsdl_operation
                processor_element << build('endpoint',               processor.endpoint)               if processor.endpoint
                processor_element << build('biomoby-authority-name', processor.biomoby_authority_name) if processor.biomoby_authority_name
                processor_element << build('biomoby-service-name',   processor.biomoby_service_name)   if processor.biomoby_service_name
                processor_element << build('biomoby-category',       processor.biomoby_category)       if processor.biomoby_category

                if processor.inputs
                  processor_element << build('inputs') do |inputs_element|
                    processor.inputs.each do |input|
                      inputs_element << build('input', input)
                    end
                  end
                end

                if processor.outputs
                  processor_element << build('outputs') do |outputs_element|
                    processor.outputs.each do |output|
                      outputs_element << build('output', output)
                    end
                  end
                end

                if processor.model
                  processor_element << aux(processor.model, 'model')
                end
              end
            end
          end

          element << build('links') do |links_element|

            model.links.each do |link|

              links_element << build('link') do |link_element|

                sink_bits   = link.sink.split(':')
                source_bits = link.source.split(':')

                link_element << build('sink') do |sink_element|
                  sink_element << build('node', sink_bits[0]) if sink_bits[0]
                  sink_element << build('port', sink_bits[1]) if sink_bits[1]
                end

                link_element << build('source') do |source_element|
                  source_element << build('node', source_bits[0]) if source_bits[0]
                  source_element << build('port', source_bits[1]) if source_bits[1]
                end
              end
            end
          end

          element << build('coordinations') do |coordinations_element|
            model.coordinations.each do |coordination|
              coordinations_element << build('coordination') do |coordination_element|
                coordination_element << build('controller', coordination.controller) if coordination.controller
                coordination_element << build('target',     coordination.target)     if coordination.target
              end
            end
          end
        end
      end

      aux(@scufl_model, 'components')
    end

    # End Instance Methods
  end
end
