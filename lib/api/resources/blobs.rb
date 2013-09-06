# myExperiment: lib/api/resources/blobs.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def file_aux(action, opts = {})

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a file") unless Authorization.check('create', Blob, opts[:user], nil)
      if opts[:query]['id']
        ob, error = obtain_rest_resource('Blob', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
      else
        ob = Blob.new(:contributor => opts[:user])
      end
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Blob', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    return rest_response(400, :reason => "Cannot delete individual versions") if opts[:query]['version']

    ob.destroy

  else

    data = LibXML::XML::Parser.string(request.raw_post).parse

    title            = parse_element(data, :text,   '/file/title')
    description      = parse_element(data, :text,   '/file/description')
    license_type     = parse_element(data, :text,   '/file/license-type')
    type             = parse_element(data, :text,   '/file/type')
    filename         = parse_element(data, :text,   '/file/filename')
    content_type     = parse_element(data, :text,   '/file/content-type')
    content          = parse_element(data, :binary, '/file/content')
    revision_comment = parse_element(data, :text,   '/file/revision-comment')

    permissions  = data.find_first('/file/permissions')

    # build the contributable

    ob.title        = title        if title
    ob.body         = description  if description

    if license_type
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

    # file name

    if filename && !filename.blank?
      ob.local_name = filename
    else
      if ob.local_name.blank?
        ob.errors.add("Filename", "missing")
        return rest_response(400, :object => ob)
      end
    end

    # handle type

    if type

      ob.content_type = ContentType.find_by_title(type)

      if ob.content_type.nil?
        ob.errors.add("Type")
        return rest_response(400, :object => ob)
      end

    elsif content_type

      content_types = ContentType.find_all_by_mime_type(content_type)

      if content_types.length == 1
        ob.content_type = content_types.first
      else
        if content_types.empty?
          ob.errors.add("Content type")
        else
          ob.errors.add("Content type", "matches more than one registered content type")
        end

        return rest_response(400, :object => ob)
      end
    end

    ob.content_blob = ContentBlob.new(:data => content) if content

    new_version  = action == 'create' && opts[:query]['id'] != nil
    edit_version = action == 'edit'   && opts[:query]['version'] != nil

    if new_version
      ob[:revision_comments] = revision_comment
    end

    success = ob.save

    if success
      case "#{action} #{new_version || edit_version}"
      when "create false"; Activity.create(:subject => opts[:user], :action => 'create', :objekt => ob, :auth => ob)
      when "create true";  Activity.create(:subject => opts[:user], :action => 'create', :objekt => ob.versions.last, :auth => ob)
      when "edit false";   Activity.create(:subject => opts[:user], :action => 'edit', :objekt => ob, :auth => ob)
      when "edit true";    Activity.create(:subject => opts[:user], :action => 'edit', :objekt => ob, :extra => ob.version, :auth => ob.blob)
      end
    end

    return rest_response(400, :object => ob) unless success

    if opts[:query]['version'].nil?
      update_permissions(ob, permissions, opts[:user])
    end
  end

  ob = ob.versioned_resource if ob.respond_to?("versioned_resource")

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_file(opts)
  file_aux('create', opts)
end

def put_file(opts)
  file_aux('edit', opts)
end

def delete_file(opts)
  file_aux('destroy', opts)
end

