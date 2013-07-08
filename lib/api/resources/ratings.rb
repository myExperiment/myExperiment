# myExperiment: lib/api/resources/ratings.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def rating_aux(action, opts)

  unless action == "destroy"

    data = LibXML::XML::Parser.string(request.raw_post).parse

    rating  = parse_element(data, :text,     '/rating/rating')
    subject = parse_element(data, :resource, '/rating/subject')
  end

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a rating") unless Authorization.check('create', Rating, opts[:user], subject)

      ob = Rating.new(:user => opts[:user])
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Rating', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    ob.rating = rating if rating

    if subject
      return rest_response(400, :reason => "Specified resource does not support ratings") unless [Blob, Network, Pack, Workflow].include?(subject.class)
      return rest_response(401, :reason => "Not authorised for the specified resource") unless Authorization.check(action, Rating, opts[:user], subject)
      ob.rateable = subject
    end

    success = ob.save

    if success
      Activity.create(:subject => opts[:user], :action => 'create', :objekt => ob, :auth => subject)
    end

    return rest_response(400, :object => ob) unless success
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_rating(opts)
  rating_aux('create', opts)
end

def put_rating(opts)
  rating_aux('edit', opts)
end

def delete_rating(opts)
  rating_aux('destroy', opts)
end
