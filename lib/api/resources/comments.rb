# myExperiment: lib/api/resources/comments.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def comment_aux(action, opts)

  unless action == "destroy"

    data = LibXML::XML::Parser.string(request.raw_post).parse

    comment = parse_element(data, :text,     '/comment/comment')
    subject = parse_element(data, :resource, '/comment/subject')
  end

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a comment") unless Authorization.check('create', Comment, opts[:user], subject)

      ob = Comment.new(:user => opts[:user])
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Comment', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    ob.comment = comment if comment

    if subject
      return rest_response(400, :reason => "Specified resource does not support comments") unless [Blob, Network, Pack, Workflow].include?(subject.class)
      return rest_response(401, :reason => "Not authorised to add a comment to the specified resource") unless Authorization.check(action, Comment, opts[:user], subject)
      ob.commentable = subject
    end

    # Start of curation hack

    def match_tag_name(name)

      name.sub!(/^c:/, '')

      matches = []

      Conf.curation_types.each do |type|
        matches.push type if type.starts_with?(name)
      end

      return matches[0] if matches.length == 1
    end

    if comment[0..1].downcase == 'c:' && opts[:user] && subject &&
        Conf.curators.include?(opts[:user].username)

      comment = comment[2..-1].strip

      lines  = comment.split("\n")
      events = []
      failed = false

      lines.each do |line|

        line.strip!

        bits = line.split(";")

        if bits.length > 1
          details = bits[1..-1].join(";")
        else
          details = nil
        end

        if bits.length > 0
          bits[0].split(",").each do |bit|

            bit.downcase!
            bit.strip!

            curation_type = match_tag_name(bit)

            if curation_type
              events.push(CurationEvent.new(:category => curation_type,
                    :object => subject, :user => opts[:user], :details => details))
            else
              failed = true
            end
          end
        end
      end

      if failed
        return rest_response(400, :reason => 'Unrecognised curation term')
      end

      events.each do |event|
        event.save
      end

      subject.solr_index

      return rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
    end

    # End of curation hack

    success = ob.save

    if success
      case action
      when "create"; Activity.create(:subject => opts[:user], :action => 'create', :objekt => ob)
      when "edit";   Activity.create(:subject => opts[:user], :action => 'edit', :objekt => ob)
      end
    end

    return rest_response(400, :object => ob) unless success
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_comment(opts)
  comment_aux('create', opts)
end

def put_comment(opts)
  comment_aux('edit', opts)
end

def delete_comment(opts)
  comment_aux('destroy', opts)
end
