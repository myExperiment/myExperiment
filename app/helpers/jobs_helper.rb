module JobsHelper
  def build_output_content(job, output_port)
    result = ''
    
    if job and output_port and (outputs = job.outputs_data)
      data = outputs[output_port]
      o_type = job.get_output_type(data)
      m_types = job.get_output_mime_types(data)
      
      case o_type
      when "list"
        if data.value.size == 1
          result += get_content(data.value, m_types)
        else
          result += "<ol class=\"outputs_list\">\n"
          result += build_nested_list(data.value, m_types)
          result += "</ol>\n"
        end
      when "string"
        result += get_content(data.value, m_types)
      else
        result += get_content(data.value, m_types)
      end
    end
    
    return result
  end
  
  def get_value(job, key, data, metadata, index)
    if metadata
      for type in metadata do
        if type.index 'image'
           image_path = "jobs/#{job.id.to_s}/#{key}"
           image = "#{index.to_s}.img"
           FileUtils.mkpath("public/#{image_path}")
           file = File.new("public/#{image_path}/#{image}", 'w+')
           file.write(Base64.decode64(data))
           file.close
           return image_tag("/#{image_path}/#{image}")
          return 'IMAGE'
        end
      end
    end
    Base64.decode64(data)
  end
  
  def mime_types_snippet(types)
    return "<span style=\"display:block;font-size:85%;color:#666666;margin-top:0.4em;\">#{types.to_sentence(:connector => '')}</span>"
  end
  
  private
  
  def build_nested_list(data_array, m_types)
    result = ''
    data_array.each do |v|
      if v.is_a?(Array)
        result += "<li><b>List:</b></li>\n"
        result += "<ol>\n"
        result += build_nested_list(v, m_types)
        result += "</ol>\n"
      elsif v.is_a?(String)
        result += "<li>#{get_content(v, m_types)}</li>\n"
      else
        result += "<li>#{get_content(v, m_types)}</li>\n"
      end
    end
    return result
  end
  
  def get_content(data, m_types)
    m = m_types.to_sentence.downcase
    if m =~ /image/
      return "This is an image!"
    elsif m =~ /html/
      return data.to_s
    else
      return "<pre>#{h data.to_s}</pre>"
    end
  end
  
end
