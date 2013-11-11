# myExperiment: lib/api/resources/packs.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def pack_aux(action, opts = {})

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a pack") unless Authorization.check('create', Pack, opts[:user], nil)
      if id = opts[:query]['id']
        ob = Pack.find_by_id(id)
        if ob.nil?
          return rest_response(404, :reason => "Couldn't find a Pack with id #{id}")
        else
          if Authorization.check('edit', ob, opts[:user])
            ob.snapshot!
            return rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
          else
            return rest_response(401, :reason => "Not authorised to snapshot pack #{id}")
          end
        end
      else
        ob = Pack.new(:contributor => opts[:user])
      end

    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Pack', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    data = LibXML::XML::Parser.string(request.raw_post).parse

    title        = parse_element(data, :text,   '/pack/title')
    description  = parse_element(data, :text,   '/pack/description')

    permissions  = data.find_first('/pack/permissions')

    if license_type = parse_element(data, :text,   '/pack/license-type')
      if license_type == ""
        ob.license = nil
      else
        ob.license = License.find_by_unique_name(license_type)

        if ob.license.nil?
          ob.errors.add("License type")
          return rest_response(400, :object => ob)
        end
      end
    end

    # build the contributable

    ob.title       = title        if title
    ob.description = description  if description

    if not ob.save
      return rest_response(400, :object => ob)
    end

    begin
      update_permissions(ob, permissions, opts[:user])
    rescue NotAuthorizedException, NotFoundException
    end
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_pack(opts)
  pack_aux('create', opts)
end

def put_pack(opts)
  pack_aux('edit', opts)
end

def delete_pack(opts)
  pack_aux('destroy', opts)
end

def pack_count(opts)

  packs = Pack.find(:all).select do |p|
    Authorization.check('view', p, opts[:user])
  end

  root = LibXML::XML::Node.new('pack-count')
  root << packs.length.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end

def external_pack_item_aux(action, opts = {})

  unless action == 'destroy'

    data = LibXML::XML::Parser.string(request.raw_post).parse

    pack          = parse_element(data, :resource, '/external-pack-item/pack')
    title         = parse_element(data, :text,     '/external-pack-item/title')
    uri           = parse_element(data, :text,     '/external-pack-item/uri')
    alternate_uri = parse_element(data, :text,     '/external-pack-item/alternate-uri')
    comment       = parse_element(data, :text,     '/external-pack-item/comment')
  end

  # Obtain object

  case action
    when 'create';

      return rest_response(401, :reason => "Not authorised to create an external pack item") unless Authorization.check('create', PackRemoteEntry, opts[:user], pack)
      return rest_response(400, :reason => "Pack not found") if pack.nil?
      return rest_response(401, :reason => "Not authorised to change the specified pack") unless Authorization.check('edit', pack, opts[:user])

      ob = PackRemoteEntry.new(:user => opts[:user],
          :pack          => pack,
          :title         => title,
          :uri           => uri,
          :alternate_uri => alternate_uri,
          :comment       => comment)

    when 'view', 'edit', 'destroy';

      ob, error = obtain_rest_resource('PackRemoteEntry', opts[:query]['id'], opts[:query]['version'], opts[:user], action)

      if ob
        return rest_response(401, :reason => "Not authorised to change the specified pack") unless Authorization.check('edit', ob.pack, opts[:user])
      end

    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    ob.title         = title         if title
    ob.uri           = uri           if uri
    ob.alternate_uri = alternate_uri if alternate_uri
    ob.comment       = comment       if comment

    if not ob.save
      return rest_response(400, :object => ob)
    end
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_external_pack_item(opts)
  external_pack_item_aux('create', opts)
end

def put_external_pack_item(opts)
  external_pack_item_aux('edit', opts)
end

def delete_external_pack_item(opts)
  external_pack_item_aux('destroy', opts)
end

def internal_pack_item_aux(action, opts = {})

  unless action == 'destroy'

    data = LibXML::XML::Parser.string(request.raw_post).parse

    pack          = parse_element(data, :resource, '/internal-pack-item/pack')
    item          = parse_element(data, :resource, '/internal-pack-item/item')
    comment       = parse_element(data, :text,     '/internal-pack-item/comment')

    version_node  = data.find_first('/internal-pack-item/item/@version')
    version       = version_node ? version_node.value.to_i : nil
  end

  # Obtain object

  case action
    when 'create';

      return rest_response(401, :reason => "Not authorised to create an internal pack item") unless Authorization.check('create', PackContributableEntry, opts[:user], pack)
      return rest_response(400, :reason => "Pack not found") if pack.nil?

      ob = PackContributableEntry.new(:user => opts[:user],
          :pack          => pack,
          :contributable => item,
          :comment       => comment,
          :contributable_version => version)

    when 'view', 'edit', 'destroy';

      ob, error = obtain_rest_resource('PackContributableEntry', opts[:query]['id'], opts[:query]['version'], opts[:user], action)

    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    ob.comment = comment if comment

    if not ob.save
      return rest_response(400, :object => ob)
    end
  end

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_internal_pack_item(opts)
  internal_pack_item_aux('create', opts)
end

def put_internal_pack_item(opts)
  internal_pack_item_aux('edit', opts)
end

def delete_internal_pack_item(opts)
  internal_pack_item_aux('destroy', opts)
end
