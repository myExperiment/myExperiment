module JobsHelper
  
  def create_list(job, key, data, metadata, index = 0)
    result = ''
    if data.kind_of? Array
      result += "<ul class=\"jobResult\">\n"
      for element in data do
        result += create_list(job, key, element, metadata, index+=1)
      end
      result += "</ul>\n"
    else
      result += "<li>#{get_value(job, key, data, metadata, index)}</li>\n"
    end
    result
  end
  
  def get_value(job, key, data, metadata, index)
    if metadata
      for type in metadata do
        if type.index 'image'
           image_path = "jobs/#{job.id.to_s}/#{key}"
           image = "#{index.to_s}.img"
           FileUtils.mkpath("public/images/#{image_path}")
           file = File.new("public/images/#{image_path}/#{image}", 'w+')
           file.write(Base64.decode64(data))
           file.close
           return image_tag("#{image_path}/#{image}")
          return 'IMAGE'
        end
      end
    end
    Base64.decode64(data)
  end
  
end
