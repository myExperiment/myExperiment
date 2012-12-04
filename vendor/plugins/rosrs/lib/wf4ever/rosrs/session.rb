# ROSRS session class
module ROSRS
  class Session

    attr_reader :uri

    ANNOTATION_CONTENT_TYPES =
      { "application/rdf+xml" => :xml,
        "text/turtle"         => :turtle,
        #"text/n3"             => :n3,
        "text/nt"             => :ntriples,
        #"application/json"    => :jsonld,
        #"application/xhtml"   => :rdfa,
      }

    PARSEABLE_CONTENT_TYPES = ['application/vnd.wf4ever.folderentry',
                               'application/vnd.wf4ever.folder',
                               'application/rdf+xml']

    # -------------
    # General setup
    # -------------

    def initialize(uri, accesskey=nil)
      @uri = URI(uri.to_s) # Force string or URI to be a URI - tried coerce, didn't work
      @key = accesskey
      @http = Net::HTTP.new(@uri.host, @uri.port)
    end

    def close
      if @http and @http.started?
        @http.finish
        @http = nil
      end
    end

    def error(code, msg, value=nil)
      # Raise exception with supplied message and optional value
      if value
        msg += " (#{value})"
      end
      msg = "Exception on #@uri #{msg}"
      case code
        when 401
          raise ROSRS::UnauthorizedException.new(msg)
        when 403
          raise ROSRS::ForbiddenException.new(msg)
        when 404
          raise ROSRS::NotFoundException.new(msg)
        when 409
          raise ROSRS::ConflictException.new(msg)
        else
          raise ROSRS::Exception.new(msg)
      end
    end

    # -------
    # Helpers
    # -------

    private

    ##
    # Parse links from headers; returns a hash indexed by link relation
    # Headerlist is a hash indexed by header field name (see HTTP:Response)
    def parse_links(headers)
      links = {}
      link_header = headers["link"] || headers["Link"]
      link_header.split(",").each do |link|
        matches = link.strip.match(/<([^>]*)>\s*;.*rel\s*=\s*"?([^;"]*)"?/)
        if matches
          links[matches[2]] ||= []
          links[matches[2]] << matches[1]
        end
      end
      links
    end

    ##
    # Extract path (incl query) for HTTP request
    # Should accept URI, RDF::URI or string values
    # Must be same host and port as session URI
    # Relative values are based on session URI
    def get_request_path(uripath)
      uripath = URI(uripath.to_s)
      if uripath.scheme && (uripath.scheme != @uri.scheme)
        error(nil, "Request URI scheme does not match session: #{uripath}")
      end
      if (uripath.host && uripath.host != @uri.host) ||
         (uripath.port && uripath.port != @uri.port)
        error(nil, "Request URI host or port does not match session: #{uripath}")
      end
      requri = URI.join(@uri.to_s, uripath.path).path
      if uripath.query
        requri += "?"+uripath.query
      end
      requri
    end

    def get_request_headers(options = {})
      if options[:headers]
        # Convert symbol keys to strings
        reqheaders = options[:headers].inject({}) do |headers, (header, value)|
          headers[header.to_s] = value
          headers
        end
      else
        reqheaders = {}
      end
      if @key
        reqheaders["authorization"] = "Bearer "+@key
      end
      if options[:ctype]
        reqheaders["content-type"] = options[:ctype]
      end
      if options[:accept]
        reqheaders['accept'] = options[:accept]
      end
      if options[:link]
        reqheaders['Link'] = options[:link]
      end
      reqheaders
    end

    public

    ##
    # Perform HTTP request
    #
    # +method+::        HTTP method name
    # +uripath+::       is reference or URI of resource (see get_request_path)
    # options:
    # [:body]    body to accompany request
    # [:ctype]   content type of supplied body
    # [:accept]  accept content types for response
    # [:headers] additional headers for request
    # Return [code, reason(text), response headers, response body]
    #
    def do_request(method, uripath, options = {})

      req = nil

      case method
      when 'GET'
        req = Net::HTTP::Get.new(get_request_path(uripath))
      when 'PUT'
        req = Net::HTTP::Put.new(get_request_path(uripath))
      when 'POST'
        req = Net::HTTP::Post.new(get_request_path(uripath))
      when 'DELETE'
        req = Net::HTTP::Delete.new(get_request_path(uripath))
      else
        error(nil, "Unrecognized HTTP method #{method}")
      end

      if options[:body]
        req.body = options[:body]
      end

      get_request_headers(options).each { |h,v| req.add_field(h, v) }
      resp = @http.request(req)
      [Integer(resp.code), resp.message, resp, resp.body]
    end

    ##
    # Perform HTTP request, following 302, 303 307 redirects
    # Return [code, reason(text), response headers, final uri, response body]
    def do_request_follow_redirect(method, uripath, options = {})
      code, reason, headers, data = do_request(method, uripath, options)
      if [302,303,307].include?(code)
        uripath = headers["location"]
        code, reason, headers, data = do_request(method, uripath, options)
      end
      if [302,307].include?(code)
        # Allow second temporary redirect
        uripath = headers["location"]
        code, reason, headers, data = do_request(method, uripath, options)
      end
      [code, reason, headers, uripath, data]
    end

    ##
    # Perform HTTP request expecting an RDF/XML response
    # Return [code, reason(text), response headers, manifest graph]
    # Returns the manifest as a graph if the request is successful
    # otherwise returns the raw response data.
    def do_request_rdf(method, uripath, options = {})
      options[:accept] ||= "application/rdf+xml"
      code, reason, headers, uripath, data = do_request_follow_redirect(method, uripath, options)
      if code >= 200 and code < 300
        begin
          data = ROSRS::RDFGraph.new(:data => data, :format => :xml)
        rescue Exception => e
          code = 902
          reason = "RDF parse failure (#{e.message})"
        end
      end
      [code, reason, headers, uripath, data]
    end

    # ---------------
    # RO manipulation
    # ---------------

    ##
    # Returns [copde, reason, uri, manifest]
    def create_research_object(name)
      code, reason, headers, uripath, data = do_request_rdf("POST", "",
          :headers    => {'slug' => name})
      if code == 201
        [code, reason, headers["location"], data]
      else
        error(code, "Error creating RO: #{code} #{reason}")
      end
    end

    def delete_research_object(ro_uri)
      #  code, reason = delete_research_object(ro_uri)
      code, reason = do_request("DELETE", ro_uri,
          :accept => "application/rdf+xml")
      if [204, 404].include?(code)
        [code, reason]
      else
        error(code, "Error deleting RO #{ro_uri}: #{code} #{reason}")
      end
    end

    def check_research_object(ro_uri)
      code, reason = do_request_follow_redirect("GET", ro_uri,
          :accept => "application/rdf+xml")

      case code
      when 200
        true
      when 404
        false
      else
        error(code, "Error checking for RO #{ro_uri}: #{code} #{reason}")
      end
    end

    # ---------------------
    # Resource manipulation
    # ---------------------

    ##
    # Aggregate internal resource
    #
    # options:
    # [:body]    body to accompany request
    # [:ctype]   content type of supplied body
    # [:accept]  accept content types for response
    # [:headers] additional headers for request
    #
    # Returns: [code, reason, proxyuri, resource_uri], where code is 200 or 201

    def aggregate_internal_resource(ro_uri, respath=nil, options={})
      if respath
        options[:headers] ||= {}
        options[:headers]['slug'] = respath
      end
      # POST resource content to indicated URI
      code, reason, headers = do_request("POST", ro_uri, options)
      unless [200,201].include?(code)
        error(code, "Error creating aggregated resource content",
                "#{code}, #{reason}, #{respath}")
      end
      proxyuri = headers["location"]
      resource_uri = parse_links(headers)[RDF::ORE.proxyFor.to_s].first
      [code, reason, proxyuri, resource_uri]
    end


    ##
    # Aggregate external resource
    #
    # Returns: [code, reason, proxyuri, resource_uri], where code is 200 or 201
    def aggregate_external_resource(ro_uri, resource_uri=nil)
      proxydata = %(
        <rdf:RDF
          xmlns:ore="http://www.openarchives.org/ore/terms/"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
          <ore:Proxy>
            <ore:proxyFor rdf:resource="#{resource_uri}"/>
          </ore:Proxy>
        </rdf:RDF>
        )
      code, reason, headers = do_request("POST", ro_uri,
        :ctype    => "application/vnd.wf4ever.proxy",
        :body     => proxydata)
      if code != 201
        error(code, "Error creating aggregation proxy",
              "#{code} #{reason} #{resource_uri}")
      else
        proxyuri = headers["location"]
        resuri = parse_links(headers)[RDF::ORE.proxyFor.to_s].first
        [code, reason, proxyuri, resuri]
      end
    end

    # -----------------------
    # Resource access
    # -----------------------

    ##
    # Retrieve resource from RO
    #
    # resuriref    is relative reference or URI of resource
    # ro_uri       is URI of RO, used as base for relative reference
    # options:
    # [:accept]    content type
    # [:headers]   additional headers for request
    # Returns:
    # [code, reason, headers, data], where code is 200 or 404
    def get_resource(resuriref, ro_uri=nil, options={})
      if ro_uri
        resuriref = URI.join(ro_uri.to_s, resuriref.to_s)
      end
      code, reason, headers, uri, data = do_request_follow_redirect("GET", resuriref, options)
      if parseable?(headers["content-type"])
        data = ROSRS::RDFGraph.new(:data => data, :format => :xml)
      end
      unless [200,404].include?(code)
        error(code, "Error retrieving RO resource: #{code}, #{reason}, #{resuriref}")
      end
      [code, reason, headers, uri, data]
    end

    ##
    # Retrieve RDF resource from RO
    #
    # resource_uri    is relative reference or URI of resource
    # ro_uri     is URI of RO, used as base for relative reference
    # options:
    # [:headers]   additional headers for request
    #
    # Returns:
    # [code, reason, headers, uri, data], where code is 200 or 404
    #
    # If code isreturned as 200, data is returned as an RDFGraph value
    def get_resource_rdf(resource_uri, ro_uri=nil, options={})
      if ro_uri
        resource_uri = URI.join(ro_uri.to_s, resource_uri.to_s)
      end
      code, reason, headers, uri, data = do_request_rdf("GET", resource_uri, options)
      unless [200,404].include?(code)
        error(code, "Error retrieving RO resource: #{code}, #{reason}, #{resource_uri}")
      end
      [code, reason, headers, uri, data]
    end

    ##
    # Retrieve an RO manifest
    #
    # Returns [manifesturi, manifest]
    def get_manifest(ro_uri)
      code, reason, headers, uri, data = do_request_rdf("GET", ro_uri)
      if code != 200
        error(code, "Error retrieving RO manifest: #{code} #{reason}")
      end
      [uri, data]
    end

    # -----------------------
    # Annotation manipulation
    # -----------------------

    ##
    # Create an annotation body from a supplied annnotation graph.
    #
    # Returns: [code, reason, body_uri]
    def create_annotation_body(ro_uri, annotation_graph)
      code, reason, bodyproxyuri, body_uri = aggregate_internal_resource(ro_uri, nil,
        :ctype => "application/rdf+xml",
        :body  => annotation_graph.serialize(format=:xml))
      if code != 201
        error(code, "Error creating annotation body resource",
              "#{code}, #{reason}, #{ro_uri}")
      end
      [code, reason, body_uri]
    end

    ##
    # Create entity body for annotation stub
    def create_annotation_stub_rdf(ro_uri, resource_uri, body_uri)
      v = { :xmlbase => ro_uri.to_s,
            :resource_uri  => resource_uri.to_s,
            :body_uri => body_uri.to_s
          }
      annotation_stub = %Q(<?xml version="1.0" encoding="UTF-8"?>
          <rdf:RDF
            xmlns:ro="http://purl.org/wf4ever/ro#"
            xmlns:ao="http://purl.org/ao/"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xml:base="#{v[:xmlbase]}"
          >
            <ro:AggregatedAnnotation>
              <ao:annotatesResource rdf:resource="#{v[:resource_uri]}" />
              <ao:body rdf:resource="#{v[:body_uri]}" />
            </ro:AggregatedAnnotation>
          </rdf:RDF>
          )
      annotation_stub
    end

    ##
    # Create an annotation stub for supplied resource using indicated body
    #
    # Returns: [code, reason, stuburi]
    def create_annotation_stub(ro_uri, resource_uri, body_uri)
      annotation = create_annotation_stub_rdf(ro_uri, resource_uri, body_uri)
      code, reason, headers, data = do_request("POST", ro_uri,
          :ctype => "application/vnd.wf4ever.annotation",
          :body  => annotation)
      if code != 201
        error(code, "Error creating annotation #{code}, #{reason}, #{resource_uri}")
      end
      [code, reason, headers["location"]]
    end

    ##
    # Create internal annotation
    #
    # Returns: [code, reason, annotation_uri, body_uri]
    def create_internal_annotation(ro_uri, resource_uri, annotation_graph)
      code, reason, headers, data = do_request("POST", ro_uri,
          :ctype => "application/rdf+xml",
          :body  => annotation_graph.serialize(format=:xml),
          :link => "<#{resource_uri}>; rel=\"#{RDF::AO.annotatesResource}\"")
      if code != 201
        error(code, "Error creating annotation #{code}, #{reason}, #{resource_uri}")
      end
      [code, reason, headers["location"], parse_links(headers)[RDF::AO.body.to_s].first]
    end

    ##
    # Create a resource annotation using an existing (possibly external) annotation body
    #
    # Returns: (code, reason, annotation_uri)
    def create_external_annotation(ro_uri, resource_uri, body_uri)
      create_annotation_stub(ro_uri, resource_uri, body_uri)
    end

    ##
    # Update an indicated annotation for supplied resource using indicated body
    #
    # Returns: [code, reason]
    def update_annotation_stub(ro_uri, stuburi, resource_uri, body_uri)
      annotation = create_annotation_stub_rdf(ro_uri, resource_uri, body_uri)
      code, reason, headers, data = do_request("PUT", stuburi,
          :ctype => "application/vnd.wf4ever.annotation",
          :body  => annotation)
      if code != 200
        error(code, "Error updating annotation #{code}, #{reason}, #{resource_uri}")
      end
      [code, reason]
    end

    ##
    # Update an annotation with a new internal annotation body
    #
    # returns: [code, reason, body_uri]
    def update_internal_annotation(ro_uri, stuburi, resource_uri, annotation_graph)
      code, reason, body_uri = create_annotation_body(ro_uri, annotation_graph)
      if code != 201
        error(code, "Error creating annotation #{code}, #{reason}, #{resource_uri}")
      end
      code, reason = update_annotation_stub(ro_uri, stuburi, resource_uri, body_uri)
      [code, reason, body_uri]
    end

    ##
    # Update an annotation with an existing (possibly external) annotation body
    #
    # returns: (code, reason)
    def update_external_annotation(ro_uri, annotation_uri, resource_uri, body_uri)
      update_annotation_stub(ro_uri, annotation_uri, resource_uri, body_uri)
    end

    ##
    # Enumerate annnotation URIs associated with a resource
    # (or all annotations for an RO)
    #
    # Returns an array of annotation statements
    def get_annotation_statements(ro_uri, resource_uri=nil)
      manifesturi, manifest = get_manifest(ro_uri)
      statements = []

      resource_uri = RDF::URI.parse(ro_uri).join(RDF::URI.parse(resource_uri)) if ro_uri

      manifest.query(:object => resource_uri) do |stmt|
        if [RDF::AO.annotatesResource,RDF::RO.annotatesAggregatedResource].include?(stmt.predicate)
          statements << stmt
        end
      end
      statements
    end

    ##
    # Enumerate annnotation URIs associated with a resource
    # (or all annotations for an RO)
    #
    # Returns an array of annotation URIs
    def get_annotation_stub_uris(ro_uri, resource_uri=nil)
      get_annotation_statements(ro_uri, resource_uri).map do |statement|
        statement.subject
      end
    end

    ##
    # Enumerate annnotation body URIs associated with a resource
    # (or all annotations for an RO)
    #
    # Returns an array of annotation body URIs
    def get_annotation_body_uris(ro_uri, resource_uri=nil)
      manifesturi, manifest = get_manifest(ro_uri)
      body_uris = []

      query1 = RDF::Query.new do
        pattern [:annotation_uri, RDF::AO.annotatesResource, RDF::URI(resource_uri)]
        pattern [:annotation_uri, RDF::AO.body, :body_uri]
      end

      query2 = RDF::Query.new do
        pattern [:annotation_uri, RDF::RO.annotatesAggregatedResource, RDF::URI(resource_uri)]
        pattern [:annotation_uri, RDF::AO.body, :body_uri]
      end

      manifest.query(query1) do |result|
        body_uris << result.body_uri.to_s
      end

      manifest.query(query2) do |result|
        body_uris << result.body_uri.to_s
      end

      body_uris.uniq
    end

    ##
    # Retrieve RDF graphs of all annnotations associated with a resource
    # (or all annotations for an RO)
    #
    # Returns graph of merged annotations
    def get_annotation_graphs(ro_uri, resource_uri=nil)
      annotation_graphs = []
      get_annotation_statements(ro_uri, resource_uri).each do |annotation_statement|
        auri   = annotation_statement.subject
        resuri = annotation_statement.object
        code, reason, headers, buri, bodytext = do_request_follow_redirect("GET", auri, {})
        if code == 200
          content_type = headers['content-type'].split(';', 2)[0].strip.downcase
          if ANNOTATION_CONTENT_TYPES.include?(content_type)
            bodyformat = ANNOTATION_CONTENT_TYPES[content_type]
            annotation_graphs << {
              :stub         => auri,
              :resource_uri => resuri,
              :body_uri     => buri,
              :body         => ROSRS::RDFGraph.new.load_data(bodytext, bodyformat)
            }
          else
            warn("Warning: #{buri} has unrecognized content-type: #{content_type}")
          end
        else
          error(code, "Failed to GET #{buri}: #{code} #{reason}")
        end
      end
      annotation_graphs
    end

    ##
    # Build RDF graph of all annnotations associated with a resource
    # (or all annotations for an RO)
    #
    # Returns graph of merged annotations
    def get_annotation_graph(ro_uri, resource_uri=nil)
      annotation_graph = ROSRS::RDFGraph.new
      get_annotation_body_uris(ro_uri, resource_uri).each do |auri|
        code, reason, headers, buri, bodytext = do_request_follow_redirect("GET", auri, {})
        if code == 200
          content_type = headers['content-type'].split(';', 2)[0].strip.downcase
          if ANNOTATION_CONTENT_TYPES.include?(content_type)
            bodyformat = ANNOTATION_CONTENT_TYPES[content_type]
            annotation_graph.load_data(bodytext, bodyformat)
          else
            warn("Warning: #{buri} has unrecognized content-type: #{content_type}")
          end
        else
          error(code, "Failed to GET #{buri}: #{code} #{reason}")
        end
      end
      annotation_graph
    end

    ##
    # Retrieve annotation for given annotation URI
    #
    # Returns: [code, reason, uri, annotation_graph]
    def get_annotation(annotation_uri)
      code, reason, headers, uri, annotation_graph = get_resource(annotation_uri)
      [code, reason, uri, annotation_graph]
    end

    ##
    # Remove annotation at given annotation URI
    #
    # Returns: (code, reason)
    def remove_annotation(annotation_uri)
      code, reason = do_request("DELETE", annotation_uri)
      if code == 204
        [code, reason]
      else
        error(code, "Failed to DELETE annotation #{annotation_uri}: #{code} #{reason}")
      end
    end

    # -----------------------
    # Folders
    # -----------------------

    ##
    # Returns [code, reason, headers, uri, folder_contents]
    def get_folder(folder_uri)
      code, reason, headers, uri, folder_contents = do_request_rdf("GET", folder_uri,
                                                                   :accept => 'application/vnd.wf4ever.folder')
      if code != 200
        error(code, reason)
      end

      [code, reason, headers, uri, folder_contents]
    end

    ##
    # +contents+ is an Array containing Hash elements, which must consist of a :uri and an optional :name.
    # Example:
    #   folder_contents = [{:name => 'test_data.txt', :uri => 'http://www.example.com/ro/file1.txt'},
    #                      {:uri => 'http://www.myexperiment.org/workflows/7'}]
    #   create_folder('ros/new_ro/', 'example_data', folder_contents)
    #
    # Returns [code, reason, uri, proxy_uri, folder_description_graph]
    def create_folder(ro_uri, name, contents = [])
      name << "/" unless name[-1] == "/" # Need trailing slash on folders...
      code, reason, headers, uripath, folder_description = do_request_rdf("POST", ro_uri,
          :body       => create_folder_description(contents),
          :headers    => {"Slug" => name,
                          "Content-Type" => 'application/vnd.wf4ever.folder',},
          :accept     => 'application/vnd.wf4ever.folder')

      if code == 201
        uri = parse_links(headers)[RDF::ORE.proxyFor.to_s].first
        [code, reason, uri, headers["location"], folder_description]
      else
        error(code, "Error creating folder: #{code} #{reason}")
      end
    end

    def add_folder_entry(folder_uri, resource_uri, resource_name = nil)
      code, reason, headers, body= do_request("POST", folder_uri,
          :body       => create_folder_entry_description(resource_uri, resource_name),
          :headers    => {"Content-Type" => 'application/vnd.wf4ever.folderentry',})
      if code == 201
        [code, reason, headers["Location"], parse_links(headers)[RDF::ORE.proxyFor.to_s].first]
      else
        error(code, "Error adding resource to folder: #{code} #{reason}")
      end
    end

    #--------

    def delete_resource(resource_uri)
      code, reason = do_request_follow_redirect("DELETE", resource_uri)
      error(code, "Error deleting resource #{resource_uri}: #{code} #{reason}") unless [204,404].include?(code)
      [code, reason]
    end

    private

    def parseable?(content_type)
      PARSEABLE_CONTENT_TYPES.include?(content_type.downcase)
    end

    ##
    # Takes +contents+, an Array containing Hash elements, which must consist of a :uri and an optional :name,
    # and returns an RDF description of the folder contents.
    def create_folder_description(contents)
      body = %(
        <rdf:RDF
          xmlns:ore="#{RDF::ORE.to_uri.to_s}"
          xmlns:rdf="#{RDF.to_uri.to_s}"
          xmlns:ro="#{RDF::RO.to_uri.to_s}" >
          <ro:Folder>
            #{contents.collect {|r| "<ore:aggregates rdf:resource=\"#{r[:uri]}\" />" }.join("\n")}
          </ro:Folder>
      )
      contents.each do |r|
        if r[:name]
          body << create_folder_entry_body(r[:uri], r[:name])
        end
      end
      body << %(
        </rdf:RDF>
      )

      body
    end

    def create_folder_entry_description(uri, name = nil)
     %(
        <rdf:RDF
          xmlns:ore="#{RDF::ORE.to_uri.to_s}"
          xmlns:rdf="#{RDF.to_uri.to_s}"
          xmlns:ro="#{RDF::RO.to_uri.to_s}" >
          #{create_folder_entry_body(uri, name)}
        </rdf:RDF>
      )
    end

    def create_folder_entry_body(uri, name = nil)
      body = %(
        <ro:FolderEntry>
      )
      body << "<ro:entryName>#{name}</ro:entryName>" if name
      body << %(<ore:proxyFor rdf:resource="#{uri}" />
        </ro:FolderEntry>
      )
      body
    end

  end
end
