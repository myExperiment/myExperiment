# myExperiment: lib/workflow_processors/interface.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

# Defines an interface that all workflow type processors need to adhere to.
module WorkflowProcessors
  require 'file_upload'
  class Blog2Template < Interface
    
    # Begin Class Methods
    
    # These: 
    # - provide information about the Workflow Type supported by this processor,
    # - provide information about the processor's capabilites, and
    # - provide any general functionality.
    
    # MUST be unique across all processors
    def self.display_name
      "Blog2 Template"
    end
    
    def self.display_data_format
      "XML"
    end
    
    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      ["xml"]
    end
    
    def self.can_determine_type_from_file?
      true
    end
    
    def self.recognised?(file)
      begin
        file.rewind
        blog_model=WorkflowProcessors::Blog2TemplateLib::Parser.parse(file.read)
        file.rewind
        return !blog_model.nil?
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
      false
    end
    
    # End Class Methods


    # Begin Object Initializer

    def initialize(workflow_definition)
      super(workflow_definition)
      @blog_model = WorkflowProcessors::Blog2TemplateLib::Parser.parse(workflow_definition)
    end

    # End Object Initializer
    
    
    # Begin Instance Methods
    
    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.
    
    def get_title
      return nil if @blog_model.nil?
      return (@blog_model.title.blank? ? "[untitled]" : @blog_model.title)
    end
    
    def get_description
      nil
    end
    
    def get_preview_image
      return nil if @blog_model.nil?

      img=Tempfile.new('image')
      img.write(@blog_model.image)
      img.rewind

      img.extend FileUpload
      img.original_filename="preview.png"
      img.content_type="image/png"

      img
    end
    
    def get_preview_svg
      nil
    end
    
    def get_workflow_model_object
      @blog_model
    end
    
    def get_workflow_model_input_ports
      
    end
    
    def get_search_terms
      ""
    end

    def get_components
      nil
    end

    # End Instance Methods
    
  end
  module Blog2TemplateLib
    class Model
      attr_accessor :title
      attr_accessor :author
      attr_accessor :image
      attr_accessor :content
    end
    module Parser
      require 'xml/libxml'
      require 'base64'
      def self.parse(xml)
        parser=LibXML::XML::Parser.string(xml)
        document=parser.parse
        post=document.find_first('/posts/post')

        return nil if post.nil?

        return create_model(post)
      end
      def self.create_model(element)
        content=element.find_first('content')
        title=element.find_first('title')
        author=element.find_first('author/name')

        return nil if (content.nil? || title.nil? || author.nil?)

        model=Blog2TemplateLib::Model.new

        model.title=title.content
        model.author=author.content
        model.content=content.content

        encoded=element.find_first("formats/format[@type='image/png']")
        model.image=Base64.decode64(encoded.content) unless encoded.nil?

        return model
      end
    end
  end
end
