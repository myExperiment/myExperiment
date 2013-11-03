# myExperiment: lib/api/resources/relationships.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def relationship_aux(action, opts)

  if action != "destroy"

    data = LibXML::XML::Parser.string(request.raw_post).parse

    subject     = parse_element(data, :resource, '/relationship/subject')
    predicate   = parse_element(data, :resource, '/relationship/predicate')
    objekt      = parse_element(data, :resource, '/relationship/object')
    context     = parse_element(data, :resource, '/relationship/context')
  end

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a relationship") unless Authorization.check('create', Relationship, opts[:user], context)
      ob = Relationship.new(:user => opts[:user])
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Relationship', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    # build it

    ob.subject   = subject   if subject
    ob.predicate = predicate if predicate
    ob.objekt    = objekt    if objekt
    ob.context   = context   if context

    if not ob.save
      return rest_response(400, :object => ob)
    end
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_relationship(opts)
  relationship_aux('create', opts)
end

def put_relationship(opts)
  relationship_aux('edit', opts)
end

def delete_relationship(opts)
  relationship_aux('destroy', opts)
end
