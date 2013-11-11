# myExperiment: lib/rest.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'conf'
require 'excel_xml'
require 'xml/libxml'
require 'uri'
require 'pivoting'
require 'will_paginate'
Dir.glob(RAILS_ROOT + '/lib/api/resources/*') {|file| require file}

include LibXML

API_VERSION = "0.1"

TABLES = parse_excel_2003_xml(File.read('config/tables.xml'),

  { 'Model' => { :indices => [ 'REST Entity' ],
                 :lists   => [ 'REST Attribute', 'Encoding', 'HTML', 'Accessor',
                               'Create', 'Read', 'Update', 'Read by default',
                               'List Element Name', 'List Element Accessor',
                               'Example', 'Versioned', 'Key type',
                               'Limited to user', 'Permission', 'Index filter' ] },
                
    'REST'  => { :indices => [ 'URI', 'Method' ] }
  } )

# Temporary removals

TABLES["REST"][:data]["job"].delete("POST")
TABLES["REST"][:data]["messages"].delete("GET")

def object_class_to_entity_name
  result = {}

  TABLES["REST"][:data].each do |path, rules|
    rules.map do |method, rules|
      next unless rules["Method"]       == "GET"
      next unless rules["Type"]         == "crud"

      result[rules["Model Entity"]] = rules["REST Entity"]
    end
  end

  result
end

OBJECT_CLASS_TO_ENTITY_NAME = object_class_to_entity_name

def rest_routes(map)
  TABLES['REST'][:data].keys.each do |uri|
    TABLES['REST'][:data][uri].keys.each do |method|
      formats = []

      formats << "xml" if TABLES['REST'][:data][uri][method]["XML"]
      formats << "rdf" if TABLES['REST'][:data][uri][method]["RDF"]

      formats.each do |format|
        map.connect "#{uri}.#{format}", :controller => 'api', :action => 'process_request', :uri => uri, :format => format
      end
    end
  end
end

def rest_response(code, args = {})

  if code == 401
    response.headers['WWW-Authenticate'] = "Basic realm=\"#{Conf.sitename} REST API\""
  end

  if code == 307
    response.headers['Location'] = args[:location]
  end

  message = "Unknown Error"

  case code
    when 200; message = "OK"
    when 307; message = "Temporary Redirect"
    when 400; message = "Bad Request"
    when 401; message = "Unauthorized"
    when 403; message = "Forbidden"
    when 404; message = "Not Found"
    when 500; message = "Internal Server Error"
  end

  if (code >= 300) && (code < 400)

    doc = ""

  else 

    error = LibXML::XML::Node.new('error')
    error["code"   ] = code.to_s
    error["message"] = message

    doc = LibXML::XML::Document.new
    doc.root = error

    if args[:object]
      args[:object].errors.full_messages.each do |message|
        reason = LibXML::XML::Node.new('reason')
        reason << message
        doc.root << reason
      end
    end

    if args[:reason]
      reason = LibXML::XML::Node.new('reason')
      reason << args[:reason]
      doc.root << reason
    end
  end

  { :xml => doc.to_s, :status => "#{code} #{message}" }
end

def resource_preview_url(ob, type, query)
  url = URI.parse(rest_resource_uri(ob))
  if query["version"]
    url.path << "/versions/#{query["version"]}"
  elsif ob.respond_to?('current_version')
    url.path << "/versions/#{ob.current_version}"
  end
  url.path << "/previews/#{type}"
  url.to_s
end

def model_entity_to_rest_entity(model_entity)
  TABLES['Model'][:data].each do |k,v|
    return k if v['Model Entity'] == model_entity
  end

  nil
end

def filter_elements(elements, prefix)
  return nil if elements.nil?
  elements[prefix]
end

def rest_get_element(ob, user, rest_entity, rest_attribute, query, elements)

  # puts "rest_get_element: #{rest_entity} / #{rest_attribute}"

  model_data = TABLES['Model'][:data][rest_entity]

  i = model_data['REST Attribute'].index(rest_attribute)

  # is this attributed limited to a particular user?

  limited_to_user = model_data['Limited to user'][i]

  if not limited_to_user.nil?
    if limited_to_user == 'self'
      limited_ob = ob
    else
      limited_ob = eval("ob.#{limited_to_user}")
    end

    return nil if limited_ob != user
  end

  permission = model_data['Permission'][i]

  if permission
    return nil if !Authorization.check(permission, ob, user)
  end

  return nil if elements.nil? || elements[model_data['REST Attribute'][i]].nil?

  if (model_data['Read'][i] == 'yes')

    accessor = model_data['Accessor'][i]

    accessor = "#{accessor}_plaintext" if query["show-plaintext"] == "yes" && model_data['HTML'][i] == "yes"

    text  = ''
    attrs = {}

    case model_data['Encoding'][i]

      when 'list', 'item as list'

        list_element = LibXML::XML::Node.new(model_data['REST Attribute'][i])

        list_select_elements = filter_elements(elements, model_data['REST Attribute'][i])
        list_select_elements = elements[model_data['REST Attribute'][i]] if elements

        attrs.each do |key,value|
          list_element[key] = value
        end

        if query['version'] and model_data['Versioned'][i] == 'yes'
          collection = eval(sprintf("ob.find_version(%d).%s", query['version'], model_data['Accessor'][i]))
        else
          collection = eval("ob.#{model_data['Accessor'][i]}")
        end

        collection = [collection] if model_data['Encoding'][i] == 'item as list'

        # filter out things that the user cannot see
        collection = collection.select do |c|
          not c.respond_to?('contribution') or Authorization.check("view", c, user)
        end

        collection.each do |item|

          item_attrs = { }

          next if item.nil?

          if model_data['List Element Name'][i]
            list_item_select_elements = filter_elements(list_select_elements, model_data['List Element Name'][i])
          else
            list_item_select_elements = filter_elements(list_select_elements, model_entity_to_rest_entity(item.class.name))
          end

          item_uri = rest_resource_uri(item)

          list_element_accessor = model_data['List Element Accessor'][i]
          list_element_item     = list_element_accessor ? eval("item.#{model_data['List Element Accessor'][i]}") : item

          if list_element_item
            if list_element_item.instance_of?(String)
              el = LibXML::XML::Node.new(model_data['List Element Name'][i])

              item_attrs['resource'] = item_uri if item_uri && query["show-resource"] != "no"
              item_attrs['uri'] = rest_access_uri(item) if query["show-uri"] != "no"
              item_attrs['id'] = item.id.to_s if query["show-id"] != "no"

              item_attrs.each do |key,value|
                el[key] = value
              end

              el << list_element_item.to_s if list_element_item

              list_element << el
            else
              el = rest_get_request_aux(list_element_item, user, query.merge({ "id" => list_element_item.id.to_s, "version" => nil }), list_item_select_elements)

              # hack to workaround an inconsistency in the established API

              if el.name == "internal-pack-item"
                el.name = rest_object_tag_text(list_element_item)
              end

              if model_data['List Element Name'][i]
                el.name = model_data['List Element Name'][i]
              end

              if list_item_select_elements.nil? || list_item_select_elements.empty? 
                el << rest_object_label_text(list_element_item)
              end

              list_element << el
            end
          end
        end

        list_element

      when 'xml'

        if query['version'] and model_data['Versioned'][i] == 'yes'
          text = eval(sprintf("ob.find_version(%d).%s", query['version'], accessor))
        else
          text = eval("ob.#{accessor}")
        end

        text

      when 'url'

        element = LibXML::XML::Node.new(model_data['REST Attribute'][i])

        element << eval("#{model_data['Accessor'][i]}(ob)")

        element

      when 'call'

        eval("#{model_data['Accessor'][i]}(ob, user, query)")

      when 'item'

        el = LibXML::XML::Node.new(model_data['REST Attribute'][i])

        if query['version'] and model_data['Versioned'][i] == 'yes'
          item = eval(sprintf("ob.find_version(%d).%s", query['version'], model_data['Accessor'][i]))
        else
          item = eval("ob.#{model_data['Accessor'][i]}")
        end

        if item != nil
          resource_uri = rest_resource_uri(item)
          el['resource'] = resource_uri if resource_uri && query["show-resource"] != "no"
          el['uri'] = rest_access_uri(item) if query["show-uri"] != "no"
          el['id'] = item.id.to_s if query["show-id"] != "no"
          el << item.label if item.respond_to?(:label) && item.label
        end

        el

      else 

        if model_data['Encoding'][i] == 'preview'

          text = resource_preview_url(ob, model_data['Accessor'][i], query)

        else

          text = ""

          if accessor
            if query['version'] and model_data['Versioned'][i] == 'yes'
              text = eval(sprintf("ob.find_version(%d).%s", query['version'], accessor)).to_s
            else

              val = eval("ob.#{accessor}")

              if val.class == ActiveSupport::TimeWithZone
                text = val.time().to_s
              else
                text = val.to_s
              end
            end
          end

          if model_data['Encoding'][i] == 'base64'
            text = Base64.encode64(text)
            attrs = { 'type' => 'binary', 'encoding' => 'base64' }
          end
        end

        # puts "ATTRIBUTE = #{model_data['REST Attribute'][i]}, ATTRS = #{attrs.inspect}, text = #{text.inspect}"

        el = LibXML::XML::Node.new(model_data['REST Attribute'][i])

        attrs.each do |key,value|
          el[key] = value if value
        end

        el << text
        el
    end
  end
end

def find_entity_name_from_object(ob)
  ob = ob.versioned_resource if ob.respond_to?(:versioned_resource)
  OBJECT_CLASS_TO_ENTITY_NAME[ob.class.name.underscore]
end

def rest_get_request_aux(ob, user, query, elements)

  rest_entity = find_entity_name_from_object(ob)

  entity = LibXML::XML::Node.new(rest_entity)

  uri      = rest_access_uri(ob)
  resource = rest_resource_uri(ob)
  version  = ob.current_version.to_s if ob.respond_to?('versions')

  version = ob.version.to_s if ob.respond_to?(:versioned_resource)

  version = query["version"] if query["version"]

  entity['uri'     ] = uri      if uri && query["show-uri"] != "no"
  entity['resource'] = resource if resource && query["show-resource"] != "no"
  entity['id'] = ob.id.to_s if query["show-id"] != "no"
  entity['version' ] = version  if version && query["show-version"] != "no"

  TABLES['Model'][:data][rest_entity]['REST Attribute'].each do |rest_attribute|
    data = rest_get_element(ob, user, rest_entity, rest_attribute, query, elements)
    entity << data unless data.nil?
  end

  entity
end

def add_to_element_hash(element, hash)
  element.split('.').each do |fragment|
    hash[fragment] = { } if hash[fragment].nil?
    hash = hash[fragment]
  end
end

def rest_get_request(ob, user, query)

  if query['version']
    return rest_response(400, :reason => "Object does not support versioning") unless ob.respond_to?('versions')
    return rest_response(404, :reason => "Specified version does not exist") if query['version'].to_i < 1
    return rest_response(404, :reason => "Specified version does not exist") if query['version'].to_i > ob.versions.last.version
  end

  # Work out which elements to include in the response.

  entity_name  = find_entity_name_from_object(ob)
  entity_rules = TABLES['Model'][:data][find_entity_name_from_object(ob)]

  elements = {}

  # "all_elements" means that all root elements are included in the response

  if query['all_elements'] == 'yes'
    entity_rules['REST Attribute'].each do |rest_attribute|
      add_to_element_hash(rest_attribute, elements)
    end
  end

  # include only root elements that are listed as "Read by default"

  if query['all_elements'].nil? && query['elements'].nil?
    entity_rules['REST Attribute'].each_index do |i|
      if entity_rules['Read by default'][i] == 'yes'
        add_to_element_hash(entity_rules['REST Attribute'][i], elements)
      end
    end
  end

  # "elements" means that only the listed elements are included in the response

  if query['elements']
    query['elements'].split(',').each do |attribute|
      add_to_element_hash(attribute, elements)
    end
  end

  doc  = LibXML::XML::Document.new()
  root = rest_get_request_aux(ob, user, query, elements) 
  doc.root = root

  root['api-version'] = API_VERSION if query['api_version'] == 'yes'

  { :xml => doc }
end

def rest_crud_request(req_uri, ob_id, format, rules, user, query)

  rest_name  = rules['REST Entity']
  model_name = rules['Model Entity']

  ob = model_name.camelize.constantize.find_by_id(ob_id.to_i)

  return rest_response(404, :reason => "Object not found") if ob.nil?

  perm_ob = ob

  perm_ob = ob.send(rules['Permission object']) if rules['Permission object']

  case rules['Permission']
    when 'public'; # do nothing
    when 'view';  return rest_response(401, :reason => "Not authorised") if not Authorization.check("view", perm_ob, user)
    when 'owner'; return rest_response(401, :reason => "Not authorised") if logged_in?.nil? or object_owner(perm_ob) != user
  end

  rest_get_request(ob, user, query)
end

def find_paginated_auth_aux(args, num, page, filters, user)

  results = yield(args, num, page)

  return nil if results.nil?

  failures = 0

  results.select do |result|

    selected = Authorization.check('view', result, user)

    if selected
      filters.each do |attribute, bits|

        lhs = eval("result.#{bits[:accessor]}")
        rhs = bits[:value]

        lhs = lhs.downcase if lhs.class == String
        rhs = rhs.downcase if rhs.class == String

        selected = false unless lhs == rhs
      end
    end

    selected
  end
end

def find_paginated_auth(args, num, page, filters, user, &blk)

  # 'upto' is the number of results needed to fulfil the request

  upto = num * page

  results = []
  current_page = 1

  # if this isn't the first page, do a single request to fetch all the pages
  # up to possibly fulfil the request

  if (page > 1)
    results = find_paginated_auth_aux(args, upto, 1, filters, user, &blk)
    current_page = page + 1
  end

  while (results.length < upto)

    results_page = find_paginated_auth_aux(args, num, current_page, filters, user, &blk)

    if results_page.nil?
      break
    else
      results += results_page
      current_page += 1
    end
  end

  range = results[num * (page - 1)..(num * page) - 1]
  range = [] if range.nil?
  range
end

def rest_index_request(req_uri, format, rules, user, query)

  rest_name  = rules['REST Entity']
  model_name = rules['Model Entity']

  default_limit = 25
  default_page  = 1

  max_limit     = 100
  min_limit     = 1

  limit = query['num']  ? query['num'].to_i  : default_limit
  page  = query['page'] ? query['page'].to_i : default_page

  limit = min_limit if limit < min_limit
  limit = max_limit if limit > max_limit

  page = 1 if page < 1

  model = TABLES["Model"][:data][TABLES["REST"][:data][req_uri]["GET"]["REST Entity"]]

  # detect filters

  filters = {}

  (0..model["REST Attribute"].length - 1).each do |i|

    if model["Index filter"][i]

      attribute   = model["REST Attribute"][i]
      filter_name = attribute.gsub("-", "_")

      if query[filter_name]

        filter = { :accessor => model["Accessor"][i] }

        if model["Encoding"][i] == 'item' || model["Encoding"][i] == 'item as list'
          filter[:value] = get_resource_from_uri(query[filter_name], user)
        else
          filter[:value] = query[filter_name]
        end

        filters[attribute] = filter
      end
    end
  end

  if query['tag']
    tag = Tag.find_by_name(query['tag'])

    if tag
      obs = (tag.taggings.select do |t| t.taggable_type == model_name.camelize end).map do |t| t.taggable end
    else
      obs = []
    end
  else

    sort       = 'id'
    order      = 'ASC'
    conditions = model_index_conditions(model_name)

    case query['sort']
      when 'created'; sort = 'created_at' if eval(model_name.camelize).new.respond_to?('created_at')
      when 'updated'; sort = 'updated_at' if eval(model_name.camelize).new.respond_to?('updated_at')
      when 'title';   sort = 'title'      if eval(model_name.camelize).new.respond_to?('title')
      when 'name';    sort = 'name'       if eval(model_name.camelize).new.respond_to?('name')
    end

    order = 'DESC' if query['order'] == 'reverse'

    find_args = { :order => "#{sort} #{order}" }

    find_args[:conditions] = conditions if conditions

    obs = find_paginated_auth( { :model => model_name.camelize, :find_args => find_args }, limit, page, filters, user) { |args, size, page|

      find_args = args[:find_args].clone

      results = args[:model].constantize.find(:all, find_args).paginate(:page => page, :per_page => size)

      results unless results.empty?
    }
  end

  produce_rest_list(req_uri, rules, query, obs, rest_name.pluralize, [], user)
end

def produce_rest_list(req_uri, rules, query, obs, tag, attributes, user)

  root = LibXML::XML::Node.new(tag)

  root['api-version'] = API_VERSION if query['api_version'] == 'yes'

  attributes.each do |k,v|
    root[k] = v
  end

  elements = {}

  if query['elements']
    query['elements'].split(',').each do |attribute|
      add_to_element_hash(attribute, elements)
    end
  end

  obs.each do |ob|

    el = rest_reference(ob, query, !elements.empty?)

    if elements.length > 0

      rest_entity = model_entity_to_rest_entity(ob.class.name)

      TABLES['Model'][:data][rest_entity]['REST Attribute'].each do |rest_attribute|
        data = rest_get_element(ob, user, rest_entity, rest_attribute, query, elements)
        el << data unless data.nil?
      end
    end

    root << el
  end

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end

def object_owner(ob)
  return User.find(ob.to) if ob.class == Message
  return ob.user  if ob.respond_to?("user")
  return ob.owner if ob.respond_to?("owner")
end

def model_index_conditions(model_name)
  case model_name
    when 'user'; return 'users.activated_at IS NOT NULL'
  end
end

def rest_resource_uri(ob)

  case ob.class.name
    when 'Workflow';               return workflow_url(ob)
    when 'Blob';                   return blob_url(ob)
    when 'Network';                return network_url(ob)
    when 'User';                   return user_url(ob)
    when 'Review';                 return workflow_review_url(ob.reviewable, ob)
    when 'Comment';                return "#{rest_resource_uri(ob.commentable)}/comments/#{ob.id}"
    when 'Bookmark';               return nil
    when 'Rating';                 return "#{rest_resource_uri(ob.rateable)}/ratings/#{ob.id}"
    when 'Tag';                    return tag_url(ob)
    when 'Picture';                return user_picture_url(ob.owner, ob)
    when 'Message';                return message_url(ob)
    when 'Citation';               return workflow_citation_url(ob.workflow, ob)
    when 'Announcement';           return announcement_url(ob)
    when 'Pack';                   return pack_url(ob)
    when 'Experiment';             return experiment_url(ob)
    when 'TavernaEnactor';         return runner_url(ob)
    when 'Job';                    return experiment_job_url(ob.experiment, ob)
    when 'PackContributableEntry'; return ob.contributable ? rest_resource_uri(ob.get_contributable_version) : nil
    when 'PackRemoteEntry';        return ob.uri
    when 'ContentType';            return content_type_url(ob)
    when 'License';                return license_url(ob)
    when 'CurationEvent';          return nil
    when 'Ontology';               return ontology_url(ob)
    when 'Predicate';              return predicate_url(ob)
    when 'Relationship';           return nil
    when 'Creditation';            return nil
    when 'Attribution';            return nil
    when 'Tagging';                return nil
    when 'WorkflowVersion';        return "#{rest_resource_uri(ob.workflow)}?version=#{ob.version}"
    when 'BlobVersion';            return "#{rest_resource_uri(ob.blob)}?version=#{ob.version}"
    when 'PackVersion';            return pack_version_url(ob, ob.version)
    when 'Policy';                 return policy_url(ob)
  end

  raise "Class not processed in rest_resource_uri: #{ob.class.to_s}"
end

def rest_access_uri(ob)

  base = "#{request.protocol}#{request.host_with_port}"

  case ob.class.name
    when 'Workflow';               return "#{base}/workflow.xml?id=#{ob.id}"
    when 'Blob';                   return "#{base}/file.xml?id=#{ob.id}"
    when 'Network';                return "#{base}/group.xml?id=#{ob.id}"
    when 'User';                   return "#{base}/user.xml?id=#{ob.id}"
    when 'Review';                 return "#{base}/review.xml?id=#{ob.id}"
    when 'Comment';                return "#{base}/comment.xml?id=#{ob.id}"
    when 'Bookmark';               return "#{base}/favourite.xml?id=#{ob.id}"
    when 'Rating';                 return "#{base}/rating.xml?id=#{ob.id}"
    when 'Tag';                    return "#{base}/tag.xml?id=#{ob.id}"
    when 'Picture';                return "#{base}/picture.xml?id=#{ob.id}"
    when 'Message';                return "#{base}/message.xml?id=#{ob.id}"
    when 'Citation';               return "#{base}/citation.xml?id=#{ob.id}"
    when 'Announcement';           return "#{base}/announcement.xml?id=#{ob.id}"
    when 'Pack';                   return "#{base}/pack.xml?id=#{ob.id}"
    when 'Experiment';             return "#{base}/experiment.xml?id=#{ob.id}"
    when 'TavernaEnactor';         return "#{base}/runner.xml?id=#{ob.id}"
    when 'Job';                    return "#{base}/job.xml?id=#{ob.id}"
    when 'Download';               return "#{base}/download.xml?id=#{ob.id}"
    when 'PackContributableEntry'; return "#{base}/internal-pack-item.xml?id=#{ob.id}"
    when 'PackRemoteEntry';        return "#{base}/external-pack-item.xml?id=#{ob.id}"
    when 'Tagging';                return "#{base}/tagging.xml?id=#{ob.id}"
    when 'ContentType';            return "#{base}/type.xml?id=#{ob.id}"
    when 'License';                return "#{base}/license.xml?id=#{ob.id}"
    when 'CurationEvent';          return "#{base}/curation-event.xml?id=#{ob.id}"
    when 'Ontology';               return "#{base}/ontology.xml?id=#{ob.id}"
    when 'Predicate';              return "#{base}/predicate.xml?id=#{ob.id}"
    when 'Relationship';           return "#{base}/relationship.xml?id=#{ob.id}"

    when 'Creditation';           return "#{base}/credit.xml?id=#{ob.id}"
    when 'Attribution';           return nil

    when 'WorkflowVersion';       return "#{base}/workflow.xml?id=#{ob.workflow.id}&version=#{ob.version}"
    when 'BlobVersion';           return "#{base}/file.xml?id=#{ob.blob.id}&version=#{ob.version}"
    when 'PackVersion';           return "#{base}/pack.xml?id=#{ob.pack.id}&version=#{ob.version}"

    when 'Policy';                 return "#{base}/policy.xml?id=#{ob.id}"
  end

  raise "Class not processed in rest_access_uri: #{ob.class.to_s}"
end

def rest_object_tag_text(ob)

  case ob.class.name
    when 'User';                   return 'user'
    when 'Workflow';               return 'workflow'
    when 'Blob';                   return 'file'
    when 'Network';                return 'group'
    when 'Rating';                 return 'rating'
    when 'Creditation';            return 'credit'
    when 'Citation';               return 'citation'
    when 'Announcement';           return 'announcement'
    when 'Tag';                    return 'tag'
    when 'Tagging';                return 'tagging'
    when 'Pack';                   return 'pack'
    when 'Experiment';             return 'experiment'
    when 'Download';               return 'download'
    when 'PackContributableEntry'; return rest_object_tag_text(ob.contributable)
    when 'PackRemoteEntry';        return 'external'
    when 'WorkflowVersion';        return 'workflow'
    when 'BlobVersion';            return 'file'
    when 'PackVersion';            return 'pack'
    when 'Comment';                return 'comment'
    when 'Bookmark';               return 'favourite'
    when 'ContentType';            return 'type'
    when 'License';                return 'license'
    when 'CurationEvent';          return 'curation-event'
    when 'Ontology';               return 'ontology'
    when 'Predicate';              return 'predicate'
    when 'Relationship';           return 'relationship'
    when 'Policy';                 return 'policy'
  end

  return 'object'
end

def rest_object_label_text(ob)

  case ob.class.name
    when 'User';                   return ob.name
    when 'Workflow';               return ob.title
    when 'Blob';                   return ob.title
    when 'Network';                return ob.title
    when 'Rating';                 return ob.rating.to_s
    when 'Creditation';            return ''
    when 'Citation';               return ob.title
    when 'Announcement';           return ob.title
    when 'Tag';                    return ob.name
    when 'Tagging';                return ob.tag.name
    when 'Pack';                   return ob.title
    when 'Experiment';             return ob.title
    when 'Download';               return ''
    when 'PackContributableEntry'; return rest_object_label_text(ob.contributable)
    when 'PackRemoteEntry';        return ob.title     
    when 'WorkflowVersion';        return ob.title
    when 'BlobVersion';            return ob.title
    when 'PackVersion';            return ob.title
    when 'ContentType';            return ob.title
    when 'License';                return ob.title
    when 'CurationEvent';          return ob.category
    when 'Ontology';               return ob.title
    when 'Predicate';              return ob.title
    when 'Relationship';           return ''
    when 'Comment';                return ob.comment
    when 'Review';                 return ob.title
    when 'Job';                    return ob.title
    when 'TavernaEnactor';         return ob.title
    when 'Policy';                 return ob.name
  end

  return ''
end

def rest_reference(ob, query, skip_text = false)

  el = LibXML::XML::Node.new(rest_object_tag_text(ob))

  resource_uri = rest_resource_uri(ob)

  el['resource'] = resource_uri if resource_uri && query["show-resource"] != "no"
  el['uri'     ] = rest_access_uri(ob) if query["show-uri"] != "no"
  el['id'] = ob.id.to_s if query["show-id"] != "no"
  el['version' ] = ob.current_version.to_s if ob.respond_to?('current_version') && query["show-version"] != "no"

  el << rest_object_label_text(ob) if !skip_text

  el
end

def  parse_resource_uri(str)

  base_uri = URI.parse("#{Conf.base_uri}/")
  uri      = base_uri.merge(str)
  is_local = base_uri.host == uri.host and base_uri.port == uri.port

  return [Workflow, $1, is_local]       if uri.path =~ /^\/workflows\/([\d]+)$/
  return [Blob, $1, is_local]           if uri.path =~ /^\/files\/([\d]+)$/
  return [Network, $1, is_local]        if uri.path =~ /^\/groups\/([\d]+)$/
  return [User, $1, is_local]           if uri.path =~ /^\/users\/([\d]+)$/
  return [Review, $1, is_local]         if uri.path =~ /^\/[^\/]+\/[\d]+\/reviews\/([\d]+)$/
  return [Comment, $1, is_local]        if uri.path =~ /^\/[^\/]+\/[\d]+\/comments\/([\d]+)$/
  return [Tag, $1, is_local]            if uri.path =~ /^\/tags\/([\d]+)$/
  return [Picture, $1, is_local]        if uri.path =~ /^\/users\/[\d]+\/pictures\/([\d]+)$/
  return [Message, $1, is_local]        if uri.path =~ /^\/messages\/([\d]+)$/
  return [Citation, $1, is_local]       if uri.path =~ /^\/[^\/]+\/[\d]+\/citations\/([\d]+)$/
  return [Announcement, $1, is_local]   if uri.path =~ /^\/announcements\/([\d]+)$/
  return [Pack, $1, is_local]           if uri.path =~ /^\/packs\/([\d]+)$/
  return [Experiment, $1, is_local]     if uri.path =~ /^\/experiments\/([\d]+)$/
  return [TavernaEnactor, $1, is_local] if uri.path =~ /^\/runners\/([\d]+)$/
  return [Job, $1, is_local]            if uri.path =~ /^\/jobs\/([\d]+)$/
  return [Download, $1, is_local]       if uri.path =~ /^\/downloads\/([\d]+)$/
  return [Ontology, $1, is_local]       if uri.path =~ /^\/ontologies\/([\d]+)$/
  return [Predicate, $1, is_local]      if uri.path =~ /^\/predicates\/([\d]+)$/

  nil

end

def get_resource_from_uri(uri, user)

  cl, id, local = parse_resource_uri(uri)

  return nil if cl.nil? || local == false

  resource = cl.find_by_id(id)

  return nil if !Authorization.check('view', resource, user)

  resource
end

def resolve_resource_node(resource_node, user = nil, permission = nil)

  return nil if resource_node.nil?

  attr = resource_node.find_first('@resource')

  return nil if attr.nil?

  resource_uri = attr.value

  resource_bits = parse_resource_uri(resource_uri)

  return nil if resource_bits.nil?
  
  resource = resource_bits[0].find_by_id(resource_bits[1].to_i)

  return nil if resource.nil?

  if permission
    return nil if !Authorization.check(permission, resource, user)
  end

  resource
end

def obtain_rest_resource(type, id, version, user, permission = nil)

  resource = eval(type).find_by_id(id)

  if resource.nil?
    return [nil, rest_response(404, :reason => "Couldn't find a #{type} with id #{id}")]
  end

  if version
    if resource.versions.last.version != version.to_i
      resource = resource.find_version(version)
    end
  end

  if resource.nil?
    return [nil, rest_response(404, :reason => "#{type} #{id} does not have a version #{version}")]
  end

  if permission
    if !Authorization.check(permission, resource, user)
      return [nil, rest_response(401, :reason => "Not authorised for #{type} #{id}")]
    end
  end

  [resource, nil]
end

def rest_access_redirect(opts = {})

  return rest_response(400, :reason => "Resource was not specified") if opts[:query]['resource'].nil?

  bits = parse_resource_uri(opts[:query]['resource'])

  return rest_response(404, :reason => "Didn't understand the format of the specified resource") if bits.nil?

  ob = bits[0].find_by_id(bits[1])

  return rest_response(404, :reason => "The specified resource does not exist") if ob.nil?

  return rest_response(401, :reason => "Not authorised for the specified resource") if !Authorization.check('view', ob, opts[:user])

  rest_response(307, :location => rest_access_uri(ob))
end

def create_default_policy(user)
  Policy.new(:contributor => user, :name => 'auto', :share_mode => 7, :update_mode => 6)
end

def update_permissions(ob, permissions, user)

  share_mode  = 7
  update_mode = 6

  # process permission elements

  if permissions

    if (group_policy = permissions.find_first('group-policy-id/text()'))

      # Check if valid id
      if (policy = Policy.find_by_id(group_policy.to_s.to_i)) && policy.group_policy?
        if user.group_policies.include?(policy)

          existing_policy = ob.contribution.policy
          existing_policy.destroy unless existing_policy.group_policy?
          ob.contribution.policy = policy
          ob.contribution.save
          return

        else
          ob.errors.add_to_base("You must be a member of #{policy.contributor.title} to use group policy: #{group_policy}")
          raise NotAuthorizedException.new
        end
      else
        ob.errors.add_to_base("#{group_policy} does not appear to be a valid group policy ID")
        raise NotFoundException.new
      end
    else

      # Create a policy for the resource if one doesn't exist, or if the previous policy was a shared one.
      if ob.contribution.policy.nil? || ob.contribution.policy.group_policy?
        ob.contribution.policy = create_default_policy(user)
        ob.contribution.save
      end

      # clear out any permission records for this contributable
      ob.contribution.policy.permissions.each do |p|
        p.destroy
      end

      permissions.find('permission').each do |permission|

        # handle public privileges

        case permission.find_first('category/text()').to_s
        when 'public'
          privileges = {}

          permission.find('privilege').each do |el|
            privileges[el['type']] = true
          end

          if privileges["view"] && privileges["download"]
            share_mode = 0
          elsif privileges["view"]
            share_mode = 2
          else
            share_mode = 7
          end
        when 'group'
          id = permission.find_first('id/text()').to_s.to_i
          privileges = {}

          permission.find('privilege').each do |el|
            privileges[el['type']] = true
          end

          network = Network.find_by_id(id)
          if network.nil?
            ob.errors.add_to_base("Couldn't share with group #{id} - Not found")
            raise
          else
            Permission.create(:contributor => network,
                              :policy => ob.contribution.policy,
                              :view => privileges["view"],
                              :download => privileges["download"],
                              :edit => privileges["edit"])
            unless (use_layout = permission.find_first('use-layout/text()')).nil?
              ob.contribution.policy.layout = network.layout_name if use_layout.to_s == 'true'
            end
          end
        end
      end
    end

    ob.contribution.policy.update_attributes(:share_mode => share_mode,
        :update_mode => update_mode)
  end
end

def paginated_search_index(query, models, num, page, user)

  return [] if not Conf.solr_enable or query.nil? or query == ""

  find_paginated_auth( { :query => query, :models => models }, num, page, [], user) { |args, size, page|

    q      = args[:query]
    models = args[:models]

    search_result = Sunspot.search models do
      fulltext q
      adjust_solr_params { |p| p[:defType] = 'edismax' }
      paginate :page => page, :per_page => size
    end

    search_result.results unless search_result.total < (size * (page - 1))
  }
end

def search(opts)

  search_query = opts[:query]['query']

  # Start of curation hack

  if search_query[0..1].downcase == 'c:' && opts[:user] &&
      Conf.curators.include?(opts[:user].username)

    bits = search_query.match("^c:([a-z]*) ([0-9]+)-([0-9]+)$")

    if bits.length == 4

      case bits[1]
        when 'workflows'; model = Workflow
        when 'files'; model = Blob
        when 'packs'; model = Pack
        else return rest_response(400, :reason => "Unknown category '#{bits[1]}'")
      end

      obs = model.find(:all, :conditions => ['id >= ? AND id <= ?', bits[2], bits[3]])

      obs = (obs.select do |c| c.respond_to?('contribution') == false or Authorization.check("view", c, opts[:user]) end)

      return produce_rest_list(opts[:req_uri], opts[:rules], opts[:query], obs, 'search', {}, opts[:user])
    end
  end

  # End of curation hack

  models = [User, Workflow, Blob, Network, Pack]

  # parse type option

  if opts[:query]['type']

    models = []

    opts[:query]['type'].split(',').each do |type|
      case type
        when 'user';     models.push(User)
        when 'workflow'; models.push(Workflow)
        when 'file';     models.push(Blob)
        when 'group';    models.push(Network)
        when 'pack';     models.push(Pack)

        else return rest_response(400, :reason => "Unknown search type '#{type}'")
      end
    end
  end

  num = 25

  if opts[:query]['num']
    num = opts[:query]['num'].to_i
  end

  num = 25  if num < 0
  num = 100 if num > 100

  page  = opts[:query]['page'] ? opts[:query]['page'].to_i : 1

  page = 1 if page < 1

  attributes = {}
  attributes['query'] = search_query
  attributes['type'] = opts[:query]['type'] if models.length == 1

  begin
    obs = paginated_search_index(search_query, models, num, page, opts[:user])
    produce_rest_list(opts[:req_uri], opts[:rules], opts[:query], obs, 'search', attributes, opts[:user])
  rescue
    rest_response(400, :reason => "Invalid search query")
  end
end

def whoami_redirect(opts)
  if opts[:user].class == User
    case opts[:format]
      when "xml"; rest_response(307, :location => rest_access_uri(opts[:user]))
      when "rdf"; rest_response(307, :location => formatted_user_url(:id => opts[:user].id, :format => 'rdf'))
    end
  else
    rest_response(401, :reason => "Not logged in")
  end
end

def parse_element(doc, kind, query)
  case kind
    when :text
      if doc.find_first(query)

        enc  = doc.find_first(query)['encoding']
        el   = doc.find_first("#{query}")
        text = doc.find_first("#{query}/text()")

        if el
          if enc == 'base64'
            return Base64::decode64(text.to_s)
          else
            return text.to_s
          end
        end
      end
    when :binary
      el   = doc.find_first("#{query}")
      text = doc.find_first("#{query}/text()")
      return Base64::decode64(text.to_s) if el
    when :resource
      return resolve_resource_node(doc.find_first(query))
  end
end

# Avatar handling (to show default avatar when none present)

def effective_avatar(ob, user, query)

  picture = ob.profile.picture

  if picture
    result = rest_reference(picture, query, true)
    result.name = "avatar"
    result
  else
    result = LibXML::XML::Node.new('avatar')
    result['resource'] = Conf.base_uri + '/images/avatar.png'
    result
  end
end

# Privileges

def effective_privileges(ob, user, query)

  privileges = LibXML::XML::Node.new('privileges')

  ['view', 'download', 'edit'].each do |type|
    if Authorization.check(type, ob, user) 
      privilege = LibXML::XML::Node.new('privilege')
      privilege['type'] = type

      privileges << privilege
    end
  end

  privileges
end

# Permissions - only visible to users with edit permissions

def permissions(ob, user, query)

  policy = ob.is_a?(Policy) ? ob : ob.contribution.policy

  def permission_node(view, download, edit, category, id = nil, layout = false)
    node = LibXML::XML::Node.new('permission')
    category_node = LibXML::XML::Node.new('category')
    category_node << category
    node << category_node
    if id
      id_node = LibXML::XML::Node.new('id')
      id_node << id
      node << id_node
    end
    if view
      privilege = LibXML::XML::Node.new('privilege')
      privilege['type'] = "view"
      node << privilege
    end
    if download
      privilege = LibXML::XML::Node.new('privilege')
      privilege['type'] = "download"
      node << privilege
    end
    if edit
      privilege = LibXML::XML::Node.new('privilege')
      privilege['type'] = "edit"
      node << privilege
    end
    if layout
      use_layout_node = LibXML::XML::Node.new('use-layout')
      use_layout_node << 'true'
      node << use_layout_node
    end

    if view || edit || download
      node
    else
      nil
    end
  end

  permissions = LibXML::XML::Node.new('permissions')
  permissions << permission_node([0,1,2].include?(policy.share_mode),
                                 policy.share_mode == 0,
                                 false,
                                 'public')

  unless ob.is_a?(Policy)
    permissions['uri'] = rest_access_uri(policy)
    permissions['resource'] = rest_resource_uri(policy)
    permissions['id'] = policy.id.to_s
    permissions['policy-type'] = policy.group_policy? ? 'group' : 'user-specified'
  end

  policy.permissions.select {|p| p.contributor_type == "Network"}.each do |perm|
    permissions << permission_node(perm.view, perm.download, perm.edit, 'group', perm.contributor_id,
                                   policy.layout == perm.contributor.layout_name)
  end

  permissions
end

# Call dispatcher

def rest_call_request(opts)
  begin
    send(opts[:rules]['Function'], opts)
  rescue Exception => e
    if Rails.env == "production"
      logger.info e.message
      logger.info e.backtrace.join("\n")
      return rest_response(500)
    else
      raise
    end
  end
end

class NotFoundException < Exception; end
class NotAuthorizedException < Exception; end
