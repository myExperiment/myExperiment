# myExperiment: lib/excel_xml.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'xml/libxml'

def parse_excel_2003_xml(xml_text, args)

  sheets = {}

  LibXML::XML::Parser.string(xml_text).parse.root.find('ss:Worksheet').each do |worksheet|

    name = worksheet['Name']
    opts = args[name]

    cells = {}
    data = {}
    registers = {}
    y = 1
    last_y = -1

    min_x = nil
    min_y = nil
    max_x = nil
    max_y = nil

    worksheet.find('ss:Table/ss:Row').each do |row|
      
      x = 1
      y = row['Index'].to_i if row['Index']

      reset_registers = true

      row.find('ss:Cell').each do |cell|
        if not cell.find_first('ss:Data').nil?
          reset_registers = false
          break
        end
      end

      reset_registers = true if y != (last_y + 1)

      registers = {} if reset_registers
  
      if opts and opts[:lists]
        opts[:lists].each do |list|
          registers.delete(list)
        end
      end
      
      row.find('ss:Cell').each do |cell| 

        x = cell['Index'].to_i if cell['Index']

          cell_data = cell.find_first('ss:Data')

          unless cell_data.nil?

            # store cell data

            cells[[x,y]] = { :data => cell_data.child.to_s,
                             :type => cell_data['Type'] }

            # update the current register

            heading = cells[[x,1]]

            unless heading.nil? or y == 1
              registers[heading[:data].gsub(/[\n\r\t]/, ' ')] = cell_data.child.to_s
            end
          end

          min_x = x if min_x.nil? or x < min_x
          max_x = x if max_x.nil? or x > max_x
          min_y = y if min_y.nil? or y < min_y
          max_y = y if max_y.nil? or y > max_y

        x = x + 1
      end

      last_y = y
      collection = data
      complete = true

      if opts and opts[:indices]
        opts[:indices].each do |index|

          if registers[index].nil?
            complete = false
            break
          end

          collection[registers[index]] = {} if collection[registers[index]].nil?
          collection = collection[registers[index]]
        end
      end

      if complete
        if opts and opts[:lists]
          opts[:lists].each do |list|
            collection[list] = [] if collection[list].nil?
          end
        end

        registers.keys.each do |register|
          if opts and opts[:lists] and opts[:lists].index(register)
            collection[register] << registers[register]
          else
            collection[register] = registers[register]
          end
        end

        if opts and opts[:lists]
          opts[:lists].each do |list|
            collection[list] << nil if registers[list].nil?
          end
        end
      end

      y = y + 1
    end

    sheets[name] = { :cells => cells, :data => data,
      :min_x => min_x, :max_x => max_x, :min_y => min_y, :max_y => max_y }

  end

  return sheets
end

