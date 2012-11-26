# ROSRS session class
module ROSRS
  class Session

    ANNOTATION_CONTENT_TYPES =
      { "application/rdf+xml" => :xml,
        "text/turtle"         => :turtle,
        #"text/n3"             => :n3,
        "text/nt"             => :ntriples,
        #"application/json"    => :jsonld,
        #"application/xhtml"   => :rdfa,
      }

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

    def error(msg, value=nil)
      # Raise exception with supplied message and optional value
      if value
        msg += " (#{value})"
      end
      raise ROSRS::Exception.new("Session::Exception on #@uri #{msg}")
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
          links[matches[2]] << URI(matches[1])
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
        error("Request URI scheme does not match session: #{uripath}")
      end
      if (uripath.host && uripath.host != @uri.host) ||
         (uripath.port && uripath.port != @uri.port)
        error("Request URI host or port does not match session: #{uripath}")
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
        error("Unrecognized HTTP method #{method}")
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
        if headers["content-type"].downcase == options[:accept]
          begin
            data = ROSRS::RDFGraph.new(:data => data, :format => :xml)
          rescue Exception => e
            code = 902
            reason = "RDF parse failure (#{e.message})"
          end
        else
          code = 901
          reason = "Non-RDF content-type returned (#{headers["content-type"]})"
        end
      end
      [code, reason, headers, uripath, data]
    end

    # ---------------
    # RO manipulation
    # ---------------

    ##
    # Returns [copde, reason, uri, manifest]
    def create_research_object(name, title, creator, date)
      reqheaders   = {
          "slug"    => name
          }
      roinfo = {
          "id"      => name,
          "title"   => title,
          "creator" => creator,
          "date"    => date
          }
      roinfotext = roinfo.to_json
      code, reason, headers, uripath, data = do_request_rdf("POST", "",
          :body       => roinfotext,
          :headers    => reqheaders)
      if code == 201
        [code, reason, headers["location"], data]
      elsif code == 409
        [code, reason, nil, data]
      else
        error("Error creating RO: #{code} #{reason}")
      end
    end

    def delete_research_object(ro_uri)
      #  code, reason = delete_research_object(ro_uri)
      code, reason = do_request("DELETE", ro_uri,
          :accept => "application/rdf+xml")
      if [204, 404].include?(code)
        [code, reason]
      else
        error("Error deleting RO #{ro_uri}: #{code} #{reason}")
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
        # POST (empty) proxy value to RO ...
      reqheaders = options[:headers] || {}
      if respath
        reqheaders['slug'] = respath
      end
      proxydata = %q(
        <rdf:RDF
          xmlns:ore="http://www.openarchives.org/ore/terms/"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
          <ore:Proxy>
          </ore:Proxy>
        </rdf:RDF>
        )
      code, reason, headers = do_request("POST", ro_uri,
        :ctype    => "application/vnd.wf4ever.proxy",
        :headers  => reqheaders,
        :body     => proxydata)
      if code != 201
        error("Error creating aggregation proxy",
              "#{code} #{reason} #{respath}")
      end
      proxyuri = URI(headers["location"])
      links    = parse_links(headers)
      resource_uri = links[RDF::ORE.proxyFor.to_s].first
      unless resource_uri
        error("No ore:proxyFor link in create proxy response",
              "Proxy URI #{proxyuri}")
      end
      # PUT resource content to indicated URI
      code, reason = do_request("PUT", resource_uri, options)
      unless [200,201].include?(code)
          error("Error creating aggregated resource content",
                "#{code}, #{reason}, #{respath}")
      end
      [code, reason, proxyuri, resource_uri]
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
      unless [200,404].include?(code)
        error("Error retrieving RO resource: #{code}, #{reason}, #{resuriref}")
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
        error("Error retrieving RO resource: #{code}, #{reason}, #{resource_uri}")
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
        error("Error retrieving RO manifest: #{code} #{reason}")
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
        error("Error creating annotation body resource",
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
          error("Error creating annotation #{code}, #{reason}, #{resource_uri}")
      end
      [code, reason, URI(headers["location"])]
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
        error("Error creating annotation #{code}, #{reason}, #{resource_uri}")
      end
      puts parse_links(headers).inspect
puts "      parse_links(headers) = #{      parse_links(headers).inspect}"
      [code, reason, URI(headers["location"]), parse_links(headers)[RDF::AO.body.to_s].first]
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
          error("Error updating annotation #{code}, #{reason}, #{resource_uri}")
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
          error("Error creating annotation #{code}, #{reason}, #{resource_uri}")
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
          error("Failed to GET #{buri}: #{code} #{reason}")
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
          error("Failed to GET #{buri}: #{code} #{reason}")
        end
      end
      annotation_graph
    end

    ##
    # Retrieve annotation for given annotation URI
    #
    # Returns: annotation_graph
    def get_annotation(annotation_uri)
      code, reason, headers, uri, annotation_graph = get_resource_rdf(annotation_uri)
      annotation_graph
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
        error("Failed to DELETE annotation #{annotation_uri}: #{code} #{reason}")
      end
    end

    # -----------------------
    # Folder manipulation
    # -----------------------

    ##
    # Returns an array of the given research object's root folders, as Folder objects.
    def get_root_folder(ro_uri, options = {})
      uri, data = get_manifest(ro_uri)
      query = RDF::Query.new do
        pattern [:research_object, RDF::RO.rootFolder,  :folder]
        pattern [:folder, RDF::ORE.isDescribedBy, :folder_resource_map]
      end

      result = data.query(query).first

      get_folder(result.folder_resource_map.to_s, options.merge({:name => result.folder.to_s}))
    end

    ##
    # Returns an RO::Folder object from the given resource map URI.
    def get_folder(folder_uri, options = {})
      folder_name = options[:name] || folder_uri.to_s.split('/').last
      ROSRS::Folder.new(self, folder_name, folder_uri, :eager_load => options[:eager_load])
    end

    ##
    # Returns an array of the given research object's root folders, as RO::Folder objects.
    # These folders have their contents pre-loaded
    # and the full hierarchy can be traversed without making further requests
    def get_folder_hierarchy(ro_uri, options = {})
      options[:eager_load] = true
      get_root_folder(ro_uri, options)
    end

    ##
    # Takes a folder URI and returns a it's description in RDF
    def get_folder_description(folder_uri)
      code, reason, headers, uripath, graph = do_request_rdf("GET", folder_uri,
                                                             :accept => 'application/vnd.wf4ever.folder')
      if code == 201
        parse_folder_description(graph)
      else
        error("Error getting folder description: #{code} #{reason}")
      end
    end

    ##
    # +contents+ is an Array containing Hash elements, which must consist of a :uri and an optional :name.
    # Example:
    #   folder_contents = [{:name => 'test_data.txt', :uri => 'http://www.example.com/ro/file1.txt'},
    #                      {:uri => 'http://www.myexperiment.org/workflows/7'}]
    #   create_folder('ros/new_ro/', 'example_data', folder_contents)
    #
    # Returns the created folder as an RO::Folder object
    def create_folder(ro_uri, name, contents = [])
      code, reason, headers, uripath, folder_description = do_request_rdf("POST", ro_uri,
          :body       => create_folder_description(contents),
          :headers    => {"Slug" => name,
                          "Content-Type" => 'application/vnd.wf4ever.folder',},
          :accept     => 'application/vnd.wf4ever.folder')

      if code == 201
        uri = parse_links(headers)[RDF::ORE.proxyFor.to_s].first
        folder = ROSRS::Folder.new(self, uri.to_s.split('/').last, uri)

        # Parse folder contents from response
        query = RDF::Query.new do
          pattern [:folder_entry, RDF.type, RDF.Description]
          pattern [:folder_entry, RDF::RO.entryName, :name]
          pattern [:folder_entry, RDF::ORE.proxyFor, :target]
          #pattern [:folder_entry, SOMETHING, :entry_uri]
        end

        folder_contents = folder_description.query(query).collect do |e|
          ROSRS::FolderEntry.new(self, e.name.to_s, e.target.to_s, e.entry_uri.to_s, folder)
        end

        folder.set_contents!(folder_contents)
        folder
      else
        error("Error creating folder: #{code} #{reason}")
      end
    end

    def delete_folder(folder_uri)
      code, reason = do_request("DELETE", folder_uri)
      error("Error deleting folder #{folder_uri}: #{code} #{reason}") unless [204, 404].include?(code)
      [code, reason]
    end

    def add_folder_entry(folder_uri, resource_uri, resource_name = nil, options = {})
      code, reason, headers, body= do_request("POST", folder_uri,
          :body       => create_folder_entry_description(resource_uri, resource_name),
          :headers    => {"Content-Type" => 'application/vnd.wf4ever.proxy',})
      if code == 201
        ROSRS::FolderEntry.new(self, resource_name, parse_links(headers)[RDF::ORE.proxyFor.to_s].first,
                            headers["Location"], options[:folder])
      else
        error("Error adding resource to folder: #{code} #{reason}")
      end
    end

    def delete_resource(resource_uri)
      code, reason = do_request("DELETE", resource_uri)
      error("Error deleting resource #{resource_uri}: #{code} #{reason}") unless code == 204
      [code, reason]
    end

    private

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
