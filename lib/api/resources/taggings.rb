# myExperiment: lib/api/resources/taggings.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def tagging_aux(action, opts)

  unless action == "destroy"

    data = LibXML::XML::Parser.string(request.raw_post).parse

    subject = parse_element(data, :resource, '/tagging/subject')
    label   = parse_element(data, :text,     '/tagging/label')
    tag     = parse_element(data, :resource, '/tagging/tag')
  end

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a tagging") unless Authorization.check('create', ActsAsTaggableOn::Tagging, opts[:user], subject)

      ob = ActsAsTaggableOn::Tagging.new(:tagger => opts[:user])
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('ActsAsTaggableOn::Tagging', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    ob.label    = label   if label
    ob.tag      = tag     if tag

    if subject
      return rest_response(401, :reason => "Not authorised for the specified resource") unless Authorization.check(action, ActsAsTaggableOn::Tagging, opts[:user], subject)
      ob.taggable = subject
    end

    success = ob.save

    if success && action == "create"
      Activity.create(:subject => opts[:user], :action => 'create', :objekt => ob, :auth => subject)
    end

    return rest_response(400, :object => ob) unless success
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_tagging(opts)
  tagging_aux('create', opts)
end

def delete_tagging(opts)
  tagging_aux('destroy', opts)
end

def get_tagged(opts)

  return rest_response(400, :reason => "Did not specify a tag") if opts[:query]['tag'].nil?

  tag = ActsAsTaggableOn::Tag.find_by_name(opts[:query]['tag'])

  obs = tag ? tag.tagged : []

  # filter out ones they are not allowed to get
  obs = (obs.select do |c| c.respond_to?('contribution') == false or Authorization.check("view", c, opts[:user]) end)

  produce_rest_list("tagged", opts[:rules], opts[:query], obs, 'tagged', [], opts[:user])
end

def tag_cloud(opts)

  num  = 25
  type = nil

  if opts[:query]['num']
    if opts[:query]['num'] == 'all'
      num = nil
    else
      num = opts[:query]['num'].to_i
    end
  end

  if opts[:query]['type'] and opts[:query]['type'] != 'all'
    type = opts[:query]['type'].camelize

    type = 'Network' if type == 'Group'
    type = 'Blob'    if type == 'File'
  end

  tags = ActsAsTaggableOn::Tag.find_by_tag_count(num, type)

  doc = LibXML::XML::Document.new()

  root = LibXML::XML::Node.new('tag-cloud')
  doc.root = root

  root['type'] = opts[:query]['type'] ? opts[:query]['type'] : 'all'

  tags.each do |tag|
    tag_node = rest_reference(tag, opts[:query])
    tag_node['count'] = tag.taggings_count.to_s
    root << tag_node
  end

  { :xml => doc }
end
