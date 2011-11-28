require 'base64'
require 'rubygems'
require 'builder'

module Baclava # :nodoc:
  
  class Writer
    
	def self.write_doc(data_map)
		REXML::Document.new(write(data_map))
	end  	

    def self.write(data_map)
      xml = Builder::XmlMarkup.new :indent => 2
      xml.instruct!
      xml.b :dataThingMap, 'xmlns:b' => 'http://org.embl.ebi.escience/baclava/0.1alpha' do
        for key in data_map.keys do
          data = data_map[key]
          xml.b :dataThing, 'key' => key do
            xml.b :myGridDataDocument, 'lsid' => '', 'syntactictype' => '' do
              #write_metadata xml, data.annotation
              write_data xml, data.value
            end
          end
        end
      end
    end
    
    #def self.write_metadata(xml, metadata)
    #  xml.s :metadata, 'xmlns:s' => 'http://org.embl.ebi.escience/xscufl/0.1alpha' do
    #    xml.s :mimeTypes do
    #      for mimetype in metadata do
    #        xml.s :mimetype, mimetype
    #      end
    #    end
    #  end    
    #end
    
    def self.write_data(xml, data, index = nil)
      if data.is_a? Array
        write_list xml, data, index
      else
        if index
          xml.b :dataElement, 'lsid' => '', 'index' => index do
            xml.b :dataElementData, Base64.encode64(data)
          end
        else
          xml.b :dataElement, 'lsid' => '' do
            xml.b :dataElementData, Base64.encode64(data)
          end
        end
      end
      
    end
    
    def self.write_list(xml, list, index)
      if index
        xml.b :partialOrder, 'lsid' => '', 'type' => 'list', 'index' => index do
          write_item_list xml, list
        end
      else
        xml.b :partialOrder, 'lsid' => '', 'type' => 'list' do
          write_item_list xml, list
        end
      end
    end
    
    def self.write_item_list(xml, list)
      xml.b :relationList
      for i in 0..list.length - 1 do
        xml.b :relation, 'parent' => i, 'child' => i + 1
      end
      xml.b :itemList do
        for i in 0..list.length - 1 do
          write_data xml, list[i], i
        end
      end
    end
    
  end
  
end