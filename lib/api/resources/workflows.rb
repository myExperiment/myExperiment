
def workflow_aux(action, opts = {})

  # Obtain object

  case action
    when 'create';
      return rest_response(401, :reason => "Not authorised to create a workflow") unless Authorization.check('create', Workflow, opts[:user], nil)
      if opts[:query]['id']
        ob, error = obtain_rest_resource('Workflow', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
      else
        ob = Workflow.new(:contributor => opts[:user])
      end
    when 'view', 'edit', 'destroy';
      ob, error = obtain_rest_resource('Workflow', opts[:query]['id'], opts[:query]['version'], opts[:user], action)
    else
      raise "Invalid action '#{action}'"
  end

  return error if ob.nil? # appropriate rest response already given

  if action == "destroy"

    return rest_response(400, :reason => "Cannot delete individual versions") if opts[:query]['version']

    ob.destroy

  else

    data = LibXML::XML::Parser.string(request.raw_post).parse

    title            = parse_element(data, :text,   '/workflow/title')
    description      = parse_element(data, :text,   '/workflow/description')
    license_type     = parse_element(data, :text,   '/workflow/license-type')
    type             = parse_element(data, :text,   '/workflow/type')
    content_type     = parse_element(data, :text,   '/workflow/content-type')
    content          = parse_element(data, :binary, '/workflow/content')
    preview          = parse_element(data, :binary, '/workflow/preview')
    svg              = parse_element(data, :text,   '/workflow/svg')
    revision_comment = parse_element(data, :text,   '/workflow/revision-comment')

    permissions  = data.find_first('/workflow/permissions')

    # build the contributable

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

    # handle workflow type

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

    ob.content_blob_id = ContentBlob.create(:data => content).id if content

    # Handle versioned metadata.  Priority:
    #
    #   1st = elements in REST request
    #   2nd = extracted metadata from workflow processor
    #   3rd = values from previous version

    metadata = Workflow.extract_metadata(:type => ob.content_type.title, :data => content)

    if title
      ob.title = title
    elsif metadata["title"]
      ob.title = metadata["title"]
    end

    if description
      ob.body = description
    elsif metadata["description"]
      ob.body = metadata["description"]
    end

    # Handle the preview and svg images.  If there's a preview supplied, use
    # it.  Otherwise auto-generate one if we can.

    begin
      if preview.nil? and content
        metadata = Workflow.extract_metadata(:type => ob.content_type.title, :data => content)
        preview = metadata["image"].read if metadata["image"]
      end

      if preview
        ob.image = preview
      end

      if svg.nil? and content
        metadata = Workflow.extract_metadata(:type => ob.content_type.title, :data => content)
        svg = metadata["image"].read if metadata["image"]
      end

      if svg
        ob.svg = svg
      end

    rescue
      return rest_response(500, :reason => "Unable to extract metadata")
    end

    new_version  = action == 'create' && opts[:query]['id'] != nil
    edit_version = action == 'edit'   && opts[:query]['version'] != nil

    if new_version
      ob.preview = nil
      ob[:revision_comments] = revision_comment
    end

    success = ob.save

    if success
      case "#{action} #{new_version || edit_version}"
      when "create false"; Activity.create(:subject => opts[:user], :action => 'create', :objekt => ob, :auth => ob)
      when "create true";  Activity.create(:subject => opts[:user], :action => 'create', :objekt => ob.versions.last, :auth => ob)
      when "edit false";   Activity.create(:subject => opts[:user], :action => 'edit', :objekt => ob, :auth => ob)
      when "edit true";    Activity.create(:subject => opts[:user], :action => 'edit', :objekt => ob, :extra => ob.version, :auth => ob.workflow)
      end
    end

    return rest_response(400, :object => ob) unless success

    # Elements to update if we're not dealing with a workflow version

    if opts[:query]['version'].nil?
      update_permissions(ob, permissions, opts[:user])
    end

    # Extract internals and stuff
    if ob.is_a?(WorkflowVersion)
      ob.workflow.extract_metadata
    else
      ob.extract_metadata
    end
  end

  ob = ob.versioned_resource if ob.respond_to?("versioned_resource")

  rest_get_request(ob, opts[:user], { "id" => ob.id.to_s })
end

def post_workflow(opts)
  workflow_aux('create', opts)
end

def put_workflow(opts)
  workflow_aux('edit', opts)
end

def delete_workflow(opts)
  workflow_aux('destroy', opts)
end

def workflow_count(opts)

  workflows = Workflow.find(:all).select do |w|
    Authorization.check('view', w, opts[:user])
  end

  root = LibXML::XML::Node.new('workflow-count')
  root << workflows.length.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end
