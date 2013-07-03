# Ontologies

def ontology_aux(action, opts)

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create an ontology") unless Authorization.check('create', Ontology, opts[:user], nil)
      ob = Ontology.new(:user => opts[:user])
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Ontology', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    data = LibXML::XML::Parser.string(request.raw_post).parse

    title        = parse_element(data, :text, '/ontology/title')
    description  = parse_element(data, :text, '/ontology/description')
    uri          = parse_element(data, :text, '/ontology/uri')
    prefix       = parse_element(data, :text, '/ontology/prefix')

    # build the contributable

    ob.title       = title       if title
    ob.description = description if description
    ob.uri         = uri         if uri
    ob.prefix      = prefix      if prefix

    if not ob.save
      return rest_response(400, :object => ob)
    end
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_ontology(opts)
  ontology_aux('create', opts)
end

def put_ontology(opts)
  ontology_aux('edit', opts)
end

def delete_ontology(opts)
  ontology_aux('destroy', opts)
end
