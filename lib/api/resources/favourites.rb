# Favourites

def favourite_aux(action, opts)

  unless action == "destroy"

    data = LibXML::XML::Parser.string(request.raw_post).parse

    target = parse_element(data, :resource, '/favourite/object')
  end

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a favourite") unless Authorization.check('create', Bookmark, opts[:user], target)

      ob = Bookmark.new(:user => opts[:user])
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Bookmark', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    if target
      return rest_response(400, :reason => "Specified resource is not a valid favourite target") unless [Blob, Pack, Workflow].include?(target.class)
      return rest_response(401, :reason => "Not authorised to create the favourite") unless Authorization.check(action, Bookmark, opts[:user], target)
      ob.bookmarkable = target
    end

    success = ob.save

    if success
      Activity.create(:subject => current_user, :action => 'create', :objekt => ob)
    end

    return rest_response(400, :object => ob) unless success
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_favourite(opts)
  favourite_aux('create', opts)
end

def put_favourite(opts)
  favourite_aux('edit', opts)
end

def delete_favourite(opts)
  favourite_aux('destroy', opts)
end
