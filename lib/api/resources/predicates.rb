# Predicates

def predicate_aux(action, opts)

  if action != "destroy"

    data = LibXML::XML::Parser.string(request.raw_post).parse

    title         = parse_element(data, :text,     '/predicate/title')
    ontology      = parse_element(data, :resource, '/predicate/ontology')
    description   = parse_element(data, :text,     '/predicate/description')
    phrase        = parse_element(data, :text,     '/predicate/phrase')
    equivalent_to = parse_element(data, :text,     '/predicate/equivalent-to')

  end

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a predicate") unless Authorization.check('create', Predicate, opts[:user], ontology)
      ob = Predicate.new
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Predicate', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    # build it

    ob.title         = title         if title
    ob.description   = description   if description
    ob.phrase        = phrase        if phrase
    ob.equivalent_to = equivalent_to if equivalent_to
    ob.ontology      = ontology      if ontology

    if not ob.save
      return rest_response(400, :object => ob)
    end
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_predicate(opts)
  predicate_aux('create', opts)
end

def put_predicate(opts)
  predicate_aux('edit', opts)
end

def delete_predicate(opts)
  predicate_aux('destroy', opts)
end
