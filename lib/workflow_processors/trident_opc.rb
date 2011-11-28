# myExperiment: lib/workflow_processors/trident_opc.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowProcessors
  class TridentOpc < WorkflowProcessors::Interface
    
    # Begin Class Methods
    
    # These: 
    # - provide information about the Workflow Type supported by this processor,
    # - provide information about the processor's capabilites, and
    # - provide any general functionality.
    
    # MUST be unique across all processors
    def self.display_name 
      "Trident (Package)"
    end
    
    def self.display_data_format
      "Package"
    end
    
    def self.mime_type
      "application/octet-stream"
    end

    # All the file extensions supported by this workflow processor.
    # Must be all in lowercase.
    def self.file_extensions_supported
      [ "zip", "twp" ]
    end
    
    def self.can_determine_type_from_file?
      true
    end
    
    # It is not possible to give a 100% gurantee that a file is a valid trident package
    # unless each zip entry is read for structure.
    # This method thus makes sure if the package file is a valid zip file and then checks
    # if it is atleast a valid OPC package by checking for a mandatory root file Content_Types,xml
    def self.recognised?(file)
      begin
        zipfile = Tempfile.new('package.zip')
        zipfile.binmode
      
        zipfile.print(file.read)
        zipfile.close
        
        Zip::ZipFile.open(zipfile.path, Zip::ZipFile::CREATE) {
            |file1|
            if nil == file1.get_entry('[Content_Types].xml')
              return false
            end
            return true
        }
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
      
      # Check if the zip file exists. If yes then remove it
      zipfile = Tempfile.new('package.zip')
      zipfile.binmode
      
      @filename = zipfile.path
      zipfile.print(workflow_definition)
      
    end

    # End Object Initializer
    def filename
        @filename = ''
   end
    
    # Begin Instance Methods
    # These provide more specific functionality for a given workflow definition, such as parsing for metadata and image generation.
    
    def get_title
        Zip::ZipInputStream::open(@filename) {
        |io|

        while (entry = io.get_next_entry)
           if entry.name.match('^.*/ActivityKind/.*xml$')    
             xml = io.read
             doc, statuses = REXML::Document.new(xml), []
             doc.elements.each('/ObjectDetails/Type') do |s1|
                if s1.text.match('Root')
                    doc.elements.each('/ObjectDetails/Label') do |s|
                        return s.text
                    end
                end
             end
         end
        end
      }
      rescue
        return ''
    end
    
    def get_description
        Zip::ZipInputStream::open(@filename) {
        |io|

        while (entry = io.get_next_entry)
           if entry.name.match('^.*/ActivityKind/.*xml$')    
             xml = io.read
             doc, statuses = REXML::Document.new(xml), []
             doc.elements.each('/ObjectDetails/Type') do |s1|
                if s1.text.match('Root')
                    doc.elements.each('/ObjectDetails/Description') do |s|
                        return s.text
                    end
                end
             end     
         end
        end
      }
      rescue
          return ''
    end
    
    def get_search_terms
        Zip::ZipInputStream::open(@filename) {
        |io|

        while (entry = io.get_next_entry)
           if entry.name.match('^.*/ActivityKind/.*xml$')    
             xml = io.read
             doc, statuses = REXML::Document.new(xml), []
             doc.elements.each('/ObjectDetails/Type') do |s1|
                if s1.text.match('Root')
                    doc.elements.each('/ObjectDetails/Keywords') do |s|
                        return s.text
                    end
                end 
             end     
         end
        end
      }
      
      rescue
          return ''
    end
    
    def get_preview_image
        Zip::ZipInputStream::open(@filename) {
        |io|
            while (entry = io.get_next_entry)
                if entry.name.match('/MyExp/Image/') 
                  return entry
                end
            end
        }
        rescue
          return nil
    end
    
    # End Instance Methods
  end
end
