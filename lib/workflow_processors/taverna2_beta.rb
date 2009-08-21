# myExperiment: lib/workflow_processors/taverna2_beta.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors

  require 't2flow/model'
  require 't2flow/parser'
  require 't2flow/dot'
  require 'libxml'
  
  require 'file_upload'

  class Taverna2Beta < Interface
    # Register Taverna 2 MIME Types
    Mime::Type.register "application/vnd.taverna.t2flow+xml", :t2flow

    # Begin Class Methods
    
    # These: 
    # - provide information about the Workflow Type supported by this processor,
    # - provide information about the processor's capabilites, and
    # - provide any general functionality.
    
    # MUST be unique across all processors
    def self.display_name 
      "Taverna 2 beta"
    end
    
    def self.display_data_format
      "T2FLOW"
    end
    
    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "t2flow" ]
    end
    
    def self.can_determine_type_from_file?
      true
    end
    
    def self.recognised?(file)
      begin
        t2flow_model = T2Flow::Parser.new.parse(file.read)
        file.rewind
        return !t2flow_model.nil?
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
      @t2flow_model = T2Flow::Parser.new.parse(workflow_definition)      
    end

    # End Object Initializer
    
    
    # Begin Instance Methods
    
    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.
    
    # *** NEW ***
    def get_name
      return nil if @t2flow_model.nil?
      if @t2flow_model.annotations.name.empty? || @t2flow_model.annotations.name=~/^(workflow|dataflow)\d*$/i
        if @t2flow_model.annotations.titles.nil? || @t2flow_model.annotations.titles.empty?
          return "[untitled]"
        else
          @t2flow_model.annotations.titles[0]
        end
      else
        @t2flow_model.annotations.name
      end
    end
    
    def get_title
      titles = self.get_titles
      if titles
        return titles[0]
      else
        return self.get_name
      end
    end
    
    # *** NEW ***
    def get_titles
      return nil if @t2flow_model.nil?
      return @t2flow_model.annotations.titles
    end
    
    def get_description
      descriptions = self.get_descriptions
      if descriptions
        desc = ""
        descriptions.each { |x| 
          desc << x
          desc << "<hr/>" unless x==descriptions.last
          }
        return desc
      else
        return nil
      end
    end
    
    # *** NEW ***
    def get_descriptions
      return nil if @t2flow_model.nil?
      return @t2flow_model.annotations.descriptions
    end

    # *** NEW ***
    def get_authors
      return nil if @t2flow_model.nil?
      return @t2flow_model.annotations.authors
    end
    
    def get_preview_image
      return nil if @t2flow_model.nil? || RUBY_PLATFORM =~ /mswin32/

      title = self.get_name
      filename = title.gsub(/[^\w\.\-]/,'_').downcase

      i = Tempfile.new("image")
      T2Flow::Dot.new.write_dot(i, @t2flow_model)
      i.close(false)
  
      img = StringIO.new(`dot -Tpng #{i.path}`)
      img.extend FileUpload
      img.original_filename = "#{filename}.png"
      img.content_type = "image/png"

      img
    end
        
    def get_preview_svg
      return nil if @t2flow_model.nil? || RUBY_PLATFORM =~ /mswin32/

      title = self.get_name
      filename = title.gsub(/[^\w\.\-]/,'_').downcase

      i = Tempfile.new("image")
      T2Flow::Dot.new.write_dot(i, @t2flow_model)
      i.close(false)

      svg = StringIO.new(`dot -Tsvg #{i.path}`)
      svg.extend FileUpload
      svg.original_filename = "#{filename}.svg"
      svg.content_type = "image/svg+xml"

      svg
    end

    def get_workflow_model_object
      @t2flow_model
    end
    
    def get_workflow_model_input_ports
      return (@t2flow_model.nil? ? nil : @t2flow_model.sources)
    end
    
    def get_search_terms
      def get_scufl_metadata(model)
        words = StringIO.new

        model.sources.each do |source|
          words << " #{source.name}" if source.name
        end

        model.sinks.each do |sink|
          words << " #{sink.name}" if sink.name
        end

        model.processors.each do |processor|
          words << " #{processor.name}" if processor.name
          words << " #{processor.description}" if processor.description
        end

        words.rewind
        words.read
      end

      return "" if @t2flow_model.nil?
      return get_scufl_metadata(@t2flow_model)
    end
    
    def get_components
      model = @t2flow_model

      components = LibXML::XML::Node.new('components')

      sources = LibXML::XML::Node.new('sources')
      sinks = LibXML::XML::Node.new('sinks')
      processors = LibXML::XML::Node.new('processors')
      datalinks = LibXML::XML::Node.new('datalinks')

      model.sources.each do |source|
        el = LibXML::XML::Node.new('source')
        el << (LibXML::XML::Node.new('name') << source.name) if source.name
        source.descriptions.each { |desc| 
          el << (XML::Node.new('description') << desc) 
        } if source.descriptions
        source.example_values.each { |ex| 
          el << (XML::Node.new('example') << ex) 
        } if source.example_values
        sources << el
      end

      model.sinks.each do |sink|
        el = LibXML::XML::Node.new('sink')
        el << (LibXML::XML::Node.new('name') << sink.name) if sink.name
        sink.descriptions.each { |desc| 
          el << (XML::Node.new('description') << desc) 
        } if sink.descriptions
        sink.example_values.each { |ex| 
          el << (XML::Node.new('example') << ex) 
        } if sink.example_values
        sinks << el
      end

      model.processors.each do |processor|
        el = LibXML::XML::Node.new('processor')
        el << (LibXML::XML::Node.new('name') << processor.name) if processor.name
        el << (LibXML::XML::Node.new('description') << processor.description) if processor.description
        el << (LibXML::XML::Node.new('type') << processor.type) if processor.type
        processors << el
      end

      model.datalinks.each do |datalink|
        el = LibXML::XML::Node.new('datalink')

        sink_bits   = datalink.sink.split(':')
        source_bits = datalink.source.split(':')

        sink   = LibXML::XML::Node.new('sink')
        source = LibXML::XML::Node.new('source')

        sink << (LibXML::XML::Node.new('node') << sink_bits[0]) if sink_bits[0]
        sink << (LibXML::XML::Node.new('port') << sink_bits[1]) if sink_bits[1]

        source << (LibXML::XML::Node.new('node') << source_bits[0]) if source_bits[0]
        source << (LibXML::XML::Node.new('port') << source_bits[1]) if source_bits[1]

        el << sink
        el << source

        datalinks << el
      end

      components << sources
      components << sinks
      components << processors
      components << datalinks

      components
    end
    
    # End Instance Methods
  end
end
