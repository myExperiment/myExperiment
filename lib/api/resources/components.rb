# Extensions to the REST API for dealing with components

##
# Retrieve a list of component URIs that match a given (restricted) SPARQL query
def get_components(opts)
  return rest_response(404) if TripleStore.instance.nil?

  sparql_prefixes = CGI.unescape(opts[:query]["prefixes"] || '')
  sparql_query = CGI.unescape(opts[:query]["query"] || '')

  # Prevent subversion of SELECT template
  if sparql_prefixes.downcase.include?("select")
    return rest_response(400, :reason => "Invalid prefix syntax")
  end

  template = %(
  PREFIX rdfs:<http://www.w3.org/2000/01/rdf-schema#>
  PREFIX wfdesc:<http://purl.org/wf4ever/wfdesc#>
  PREFIX wf4ever:<http://purl.org/wf4ever/wf4ever#>
  #{sparql_prefixes}

  SELECT DISTINCT ?workflow_uri WHERE {
    GRAPH ?workflow_uri {
      ?w a wfdesc:Workflow .
      #{sparql_query}
    }
  })

  # Perform query
  begin
    sparql_results = TripleStore.instance.query(template)
  rescue Sesame::QueryException => e
    return rest_response(400, :reason => "SPARQL Error: #{e.message}")
  end

  # Map the returned URIs to actual workflow objects
  results = sparql_results.map { |r| resource_from_uri(r[:workflow_uri]) }.compact

  results = results.select do |workflow|
    # Check workflow is a component and that the user can view it
    workflow.component? && Authorization.check("view", workflow, opts[:user])
  end

  # Filter by component family, if given
  component_family_uri = opts[:query]['component-family']
  if component_family_uri
    component_family = resource_from_uri(component_family_uri)
    if component_family.nil?
      return rest_response(404, :reason => 'Component family not found')
    elsif !component_family.is_a?(Pack) || !component_family.component_family?
      return rest_response(400, :reason => "No valid component family found at #{component_family_uri}")
    else
      # Take the intersection of the current list of components and the components in the family
      results = results & component_family.contributable_entries.map { |e| e.contributable }
    end
  end

  # Render results
  produce_rest_list(opts[:uri], opts[:rules], opts[:query], results, "workflows", [], opts[:user])
end


##
# Retrieve a component
def get_component(opts)
  #opts[:query]['all_elements'] = "yes"
  rest_crud_request(opts[:req_uri], opts[:query]['id'], opts[:format],
      {'Model Entity' => 'workflow',
       'Permission' => 'view'},
      opts[:user], opts[:query])
end


##
# Create a new component in the specified family
def post_component(opts)
  # Check if posting a new version of an existing component (id present)
  id = opts[:query]['id']
  if id
    component = Workflow.find_by_id(id.to_i)
    unless component && component.component?
      return rest_response(404, :reason => "Component not found")
    end
  else # Otherwise, we're creating a new component
    data = LibXML::XML::Parser.string(request.raw_post).parse

    # Get the component family
    component_family_uri = parse_element(data, :text, '/workflow/component-family')
    family = resource_from_uri(component_family_uri)
    if family.nil?
      return rest_response(404, :reason => 'Component family not found')
    elsif !family.is_a?(Pack)  || !family.component_family?
      return rest_response(400, :reason => "No valid component family found at #{component_family_uri}")
    elsif !Authorization.check('edit', family, opts[:user])
      return rest_response(401, :reason => "You are not authorized to add components to this component family")
    end
  end

  # Create the component or version
  response = workflow_aux('create', opts)

  # If we created a new component, we need to tag it and add it to the family
  unless id
    # Awful hack to get the newly created component
    component = resource_from_uri(response[:xml].find_first('//workflow')['resource'])

    # Add the component to the family
    PackContributableEntry.create(:pack => family, :contributable => component, :user => opts[:user])

    # Add the tag
    tag = Tag.find_or_create_by_name('component')
    Tagging.create(:tag => tag, :taggable => component, :user => opts[:user])
  end

  rest_get_request(component, opts[:user], { "id" => component.id.to_s })
end


##
# Retrieve an XML representation of a component family
#
# Can filter by component profile, by specifying the component profile URI in the component-profile parameter
# e.g. GET component-families.xml?component-profile=http://www.myexperiment.org/files/124
def get_component_families(opts)
  # Find all component family packs
  families = Pack.component_families

  # Filter by component profile, if given
  component_profile_uri = opts[:query]['component-profile']
  if component_profile_uri
    component_profile = resource_from_uri(component_profile_uri)
    if component_profile.nil?
      return rest_response(404, :reason => 'Component profile not found')
    else
      # Check for the given component profile in the set of families
      families = families.select { |family| family.component_profile == component_profile }
    end
  end

  # Authorization
  families = families.select { |r| Authorization.check("view", r, opts[:user]) }

  # Render results
  produce_rest_list(opts[:uri], opts[:rules], opts[:query], families, "component-families", [], opts[:user])
end


##
# Retrieve an XML representation of a component family
def get_component_family(opts)
  opts[:query]['all_elements'] = "yes"
  rest_crud_request(opts[:req_uri], opts[:query]['id'], opts[:format],
      {'Model Entity' => 'pack',
       'Permission' => 'view'},
      opts[:user], opts[:query])
end


##
# Create a new component family
def post_component_family(opts)
  # Get the component profile
  data = LibXML::XML::Parser.string(request.raw_post).parse
  component_profile_uri = parse_element(data, :text, '/pack/component-profile')

  unless component_profile_uri
    return rest_response(400, :reason => "Missing component profile URI")
  end

  component_profile = resource_from_uri(component_profile_uri)

  if component_profile.nil?
    return rest_response(404, :reason => "No component profile found at: #{component_profile_uri}")
  elsif !component_profile.is_a?(Blob) && !component_profile.is_a?(BlobVersion)
    return rest_response(400, :reason => "#{component_profile_uri} is not a valid component profile (not a file)")
  elsif component_profile.content_type.mime_type != 'application/vnd.taverna.component-profile+xml'
    return rest_response(400, :reason => "#{component_profile_uri} is not a valid component profile (wrong MIME type)")
  end

  # Create the component family
  response = pack_aux('create', opts)

  # Awful hack to get the newly created component family
  family = resource_from_uri(response[:xml].find_first('//pack')['resource'])

  # Add the profile
  if component_profile.is_a?(Blob)
    PackContributableEntry.create(:pack => family, :contributable => component_profile, :user => opts[:user])
  elsif component_profile.is_a?(BlobVersion)
    PackContributableEntry.create(:pack => family, :contributable => component_profile.blob,
                                  :contributable_version => component_profile.version, :user => opts[:user])
  end

  # Add the tag
  tag = Tag.find_or_create_by_name('component family')
  Tagging.create(:tag => tag, :taggable => family, :user => opts[:user])

  # Return resource
  rest_get_request(family, opts[:user], { "id" => family.id.to_s })
end


##
# Delete a component family and all components inside it
def delete_component_family(opts)
  # Find the family
  id = opts[:query]['id']
  family = Pack.find_by_id(id)
  if family.nil? || !family.component_family?
    return rest_response(404, :reason => "Couldn't find a valid component family with the given ID")
  end

  # Check if user has permission to delete the family
  unless Authorization.check('destroy', family, opts[:user])
    family.errors.add_to_base("You don't have permission to delete this component family.")
    return rest_response(401, :object => family)
  end

  # Check if can delete ALL components in family
  component_entries = family.contributable_entries.select { |e| e.contributable_type == 'Workflow' && e.contributable.component? }
  components = component_entries.map { |e| e.contributable }
  undeletable_components = components.select { |c| !Authorization.check('destroy', c, opts[:user]) }
  if undeletable_components.size == 0
    # Delete all components
    components.each { |c| c.destroy }

    # Delete family
    family.destroy

    rest_get_request(family, opts[:user], opts[:query])
  else
    family.errors.add_to_base("You don't have permission to delete #{undeletable_components.size} components in this component family.")
    rest_response(401, :object => family)
  end
end


##
# Retrieve a list of component profiles
def get_component_profiles(opts)
  profiles = Blob.component_profiles

  # Authorization
  profiles = profiles.select { |r| Authorization.check("view", r, opts[:user]) }

  # Render results
  produce_rest_list(opts[:uri], opts[:rules], opts[:query], profiles, "component-profiles", [], opts[:user])
end


##
# Retrieve a component profile
def get_component_profile(opts)
  rest_crud_request(opts[:req_uri], opts[:query]['id'], opts[:format],
      {'Model Entity' => 'blob',
       'Permission' => 'view'},
      opts[:user], opts[:query])
end


##
# Create a new component profile
def post_component_profile(opts)
  response = file_aux('create', opts)

  # Return error from creation attempt, if any
  return response if response[:status] && response[:status][0] != '2'

  # Awful hack to get the newly created profile object
  profile = resource_from_uri(response[:xml].find_first('//file')['resource'])

  # Add the tag
  tag = Tag.find_or_create_by_name('component profile')
  Tagging.create(:tag => tag, :taggable => profile, :user => opts[:user])

  # Return resource
  rest_get_request(profile, opts[:user], { "id" => profile.id.to_s })
end


##
# Delete a component profile
def delete_component_profile(opts)
  # Find the profile
  id = opts[:query]['id']
  profile = Blob.find_by_id(id)
  if profile.nil? || !profile.component_profile?
    return rest_response(404, :reason => "Couldn't find a valid component profile with the given ID")
  end

  # Check if profile is used in any component families
  families = PackContributableEntry.find_all_by_contributable_type_and_contributable_id('Blob', profile.id).select do |e|
    e.pack.component_family?
  end
  if families.size == 0
    # Delete profile
    profile.destroy

    rest_get_request(profile, opts[:user], opts[:query])
  else
    profile.errors.add_to_base("This component profile is used by #{families.size} component families and may not be deleted.")
    rest_response(400, :object => profile)
  end
end

private

# Checks if a given URI is a resource from THIS application
def internal_resource_uri?(uri)
  uri = URI.parse(uri) if uri.is_a?(String)
  base_uri = URI.parse(Conf.base_uri)

  uri.relative? || uri.host == base_uri.host && uri.port == base_uri.port
end

# Gets an internal resource from a given URI
def resource_from_uri(uri)
  if uri.is_a?(String)
    uri = URI.parse(uri)
  end

  resource = nil

  if internal_resource_uri?(uri)
    begin
      route = ActionController::Routing::Routes.recognize_path(uri.path, :method => :get)
      if route[:action] == "show"
        resource = Object.const_get(route[:controller].camelize.singularize).find_by_id(route[:id].to_i)
      else
        nil
      end

      resource = resource.find_version(route[:version].to_i) if route[:version]
    rescue ActionController::RoutingError
      logger.warn("Unrecognized resource URI: #{uri}")
      nil
    rescue ActiveRecord::RecordNotFound
      logger.warn("Couldn't find version #{route[:version]} for URI: #{uri}")
      nil
    end
  end

  resource
end
