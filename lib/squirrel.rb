#
#
# Copyright (c) 2007, Mark Borkum (mib104@ecs.soton.ac.uk)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# 

module Squirrel # :nodoc

  # The Squirrel serves a single purpose, to convert the SQL dump of a database into a 
  # format that is useful for a dba (particularly when the database corresponds to a Rails model).
  #
  # This function takes two parameters, the path to the +sql_dump+ file and a list of table names 
  # to be +exclude+d from the resulting hash. The +schema_info+ table is automatically removed if found. 
  #
  # The returned hash has a key for each table name, each value is an array of hashs, where each hash
  # is a mapping between schema attributes and "INSERT INTO..." values. 
  #
  # == Useage
  # include Squirrel
  # myhash = Squirrel.sql_to_hash(myfile.path, "foobars")
  # myhash.each do |table_name, objects|
  #   objects.each do |object|
  #     # do something with object
  #   end
  # end
  def self.sql_to_hash(sql_dump, *exclude)
    rtn = {}
    
    read(sql_dump, rtn)
    
    exclude << "schema_info" if rtn["schema_info"] and !exclude.include?("schema_info")
    exclude.each do |table_name|
      rtn.delete(table_name) if rtn.key?(table_name)
    end
  
    parse(rtn)
  
    return rtn
  end

private

  def chomper(str)
    current = str[i = 0, 1]
  
    if current =~ /\d/
      output = current
    
      i = i.to_i + 1
      while true
        current = str[i, 1]
        if current =~ /\d/
          output = output + current
        else
          break
        end
        i = i.to_i + 1
      end
      return output, str[i.to_i + 1...str.length]
    elsif current =~ /'/
      output = ""
    
      i = i.to_i + 1
      while true
        current = str[i, 1]
        if current =~ /'/
          if (i.to_i + 1 == str.length) or str[i.to_i + 1, 1] =~ /,/
            break
          else
            output = output + current
          end
        else
          output = output + current
        end
        i = i.to_i + 1
      end
      return output, str[i.to_i + 2...str.length]
    elsif current =~ /N/
      output = (str[i, 4] =~ /NULL/) ? "NULL" : ""
      return output, str[i.to_i + 5...str.length]
    else
      # nothing
    end
  end

  def chomp(str)
    rtn = []
  
    input = str
    while true
      output, input = chomper(input)
      rtn << output
      break if input.nil?
    end
  
    return rtn
  end

  def read(file, hash)
    arr, i = File.open(file).readlines, 0
    while i < arr.length
      if arr[i] =~ /^CREATE TABLE `([a-z_]*)`/
        hash[key = $1] ||= []
        schema = []
    
        while true
          if arr[i = i.to_i + 1] =~ /^\s*`([a-z_]*)`/
            attribute = $1
            schema << attribute
          else
            break
          end
        end
    
        hash[key] << schema.join(",")
      elsif arr[i] =~ /^INSERT INTO `([a-z_]*)` VALUES (.*)$/
        key, tuples = $1, $2
        tuples[1..-3].split("),(").each do |tuple| 
          hash[key] << tuple
        end
      else
        # do nothing
      end
  
      i = i.to_i + 1
    end
  end

  def parse(hash)
    hash.keys.sort.each do |table_name|
      schema = hash[table_name][0].split(",")
    
      i = 1
      while i < hash[table_name].length
        input, record = hash[table_name][i], { "type" => table_name.classify }
        chomped = chomp(input)
      
        j = 0
        while j < schema.length
          record[schema[j]] = (chomped[j] =~ /NULL/) ? nil : chomped[j]
          j = j.to_i + 1
        end
        hash[table_name][i] = record
        i = i.to_i + 1
      end
    
      hash[table_name][0] = nil
      hash[table_name].compact!
    end
  end

end