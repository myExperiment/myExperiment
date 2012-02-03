require "rexml/document"
require "document/data"

module Baclava
  
  class Reader
    
    #Reads a baclava document amd returns a hash of Document::Data objects
    def self.read(xml)
      if xml.kind_of?(REXML::Document)
      	document = xml
      else
        document = REXML::Document.new(xml)
      end
      root = document.root
      raise "'#{root.name}' doesn't appear to be a data thing!" if root.name != "dataThingMap"
      
      create_data_map(root)
    end
    
    def self.create_data_map(element)
      data_map = {}
      
      element.each_element('b:dataThing') { |datathing|
        key = datathing.attribute('key').value
        data = Document::Data.new
        data_map[key] = data
        datathing.each_element('b:myGridDataDocument')  { |dataDocument|
          dataDocument.each_element('s:metadata')  { |metadata| data.annotation = get_metadata(metadata) }
          dataDocument.each_element('b:partialOrder') { |partialOrder| data.value = get_list(partialOrder) }
          dataDocument.each_element('b:dataElement')  { |dataElement| data.value = get_element(dataElement) }
        }
      }
      
      data_map   
    end
    
    def self.get_list(element)
      list = []
      element.each_element('b:itemList') { |itemList|  
        itemList.each_element('b:dataElement')  { |dataElement| list << get_element(dataElement) }
        itemList.each_element('b:partialOrder') { |partialOrder| list << get_list(partialOrder) }
      }
      list
    end
    
    def self.get_metadata(element)
      list = []
      element.each_element('s:mimeTypes') { |mimeTypes|
        mimeTypes.each_element('s:mimeType')  { |mimeType| list << mimeType.text }
      }
      list
    end
    
    def self.get_element(element)
      element.each_element('b:dataElementData') { |data| return Base64.decode64(data.text) }
    end
    
  end
  
end
