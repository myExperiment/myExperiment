# myExperiment: config/initializers/web_cache.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

class ROSRS::Session

  alias_method :original_do_request, :do_request

  def do_request(method, uripath, options = {})

    def cache_file_name(uri)
      "tmp/webcache/#{Rack::Utils.escape(uri)}"
    end

    def exist_in_cache?(uri)

      # FIXME: The manifest check here is hacky.  This really ought to be done
      # with appropriate HTTP headers.

      return false if uri.ends_with?("manifest.rdf")

      File.exist?(cache_file_name(uri))
    end

    def load_from_cache(uri)
      YAML::load(File.read(cache_file_name(uri)))
    end

    def save_to_cache(uri, data)
      File.open(cache_file_name(uri), "w+") do |f|
        f.puts(data.to_yaml)
      end
    end

    def delete_from_cache(uri)
      File.delete(cache_file_name(uri))
    end

    if exist_in_cache?(uripath)
      if method == "GET"
        Rails.logger.info("Using #{uripath.inspect} from web cache.")
        return load_from_cache(uripath)
      else
        Rails.logger.info("Deleting #{uripath.inspect} from web cache.")
        delete_from_cache(uripath)
      end
    end

    code, message, response, body = original_do_request(method, uripath, options)

    headers = {}

    response.each_header do |k, v|
      headers[k] = v
    end

    if method == "GET"
      Rails.logger.info("Adding #{uripath.inspect} to web cache.")
      save_to_cache(uripath, [code, message, headers, body])
    end

    [code, message, headers, body]
  end
end

