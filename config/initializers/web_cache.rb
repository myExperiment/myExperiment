# myExperiment: config/initializers/web_cache.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

class Thread
  attr_accessor :read_manifest
end

ApplicationController # ensure that the application controller is loaded

class ApplicationController
  before_filter do |controller|
    Thread.current.read_manifest = false
  end
end

class ROSRS::Session

  alias_method :original_do_request, :do_request

  def do_request(method, uripath, options = {})

    def cache_file_name(uri)
      "tmp/webcache/#{Digest::SHA1.hexdigest(uri)}"
    end

    def exist_in_cache?(uri)

      return false if uri.blank?

      # FIXME: The manifest check here is hacky.  This really ought to be done
      # with appropriate HTTP headers.  I've added an attribute to the Thread
      # class so that we can tell if we've read the manifest already whilst
      # serving this request.

      return false if uri.ends_with?("manifest.rdf") && Thread.current.read_manifest == false

      File.exist?(cache_file_name(uri))
    end

    def load_from_cache(uri)
      envelope = YAML::load(File.read(cache_file_name(uri)))
      [envelope[:status], envelope[:reason], envelope[:headers], envelope[:body]]
    end

    def save_to_cache(uri, data)

      envelope = {
        :uri       => uri,
        :timestamp => Time.now.to_s,
        :status    => data[0],
        :reason    => data[1],
        :headers   => data[2],
        :body      => data[3]
      }

      File.open(cache_file_name(uri), "w+") do |f|
        f.puts(envelope.to_yaml)
      end

      # FIXME: The manifest handling here is hacky.

      Thread.current.read_manifest = true if uri.ends_with?("manifest.rdf")
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

