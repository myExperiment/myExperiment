# myExperiment: lib/rest.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'lib/conf'
require 'lib/excel_xml'
require 'xml/libxml'
require 'uri'

include LibXML

API_VERSION = "0.1"

TABLES = parse_excel_2003_xml(File.read('config/tables.xml'),

  { 'Model' => { :indices => [ 'REST Entity' ],
                 :lists   => [ 'REST Attribute', 'Encoding', 'Accessor',
                               'Create', 'Read', 'Update', 'Read by default',
                               'Foreign Accessor',
                               'List Element Name', 'List Element Accessor',
                               'Example', 'Versioned', 'Key type',
                               'Limited to user', 'Permission', 'Index filter' ] },
                
    'REST'  => { :indices => [ 'URI', 'Method' ] }
  } )

# Temporary removals

TABLES["REST"][:data]["job"].delete("POST")
TABLES["REST"][:data]["messages"].delete("GET")

def rest_routes(map)
  TABLES['REST'][:data].keys.each do |uri|
    TABLES['REST'][:data][uri].keys.each do |method|
      map.connect "#{uri}.xml", :controller => 'api', :action => 'process_request', :uri => uri
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
    when 200: message = "OK"
    when 307: message = "Temporary Redirect"
    when 400: message = "Bad Request"
    when 401: message = "Unauthorized"
    when 403: message = "Forbidden"
    when 404: message = "Not Found"
    when 500: message = "Internal Server Error"
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

  render(:xml => doc.to_s, :status => "#{code} #{message}")
end

def file_column_url(ob, field)

  fields = (field.split('/').map do |f| "'#{f}'" end).join(', ')

  path = eval("ActionView::Base.new.url_for_file_column(ob, #{fields})")

  "#{request.protocol}#{request.host_with_port}#{path}"
end

def model_entity_to_rest_entity(model_entity)
  TABLES['Model'][:data].each do |k,v|
    return k if v['Model Entity'] == model_entity
  end

  nil
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
    return nil if !Authorization.is_authorized?(permission, nil, ob, user)
  end

  unless query['all_elements'] == 'yes'
    return nil if elements and not elements.index(model_data['REST Attribute'][i])
    return nil if not elements and model_data['Read by default'][i] == 'no'
  end

  if (model_data['Read'][i] == 'yes')

    accessor = model_data['Accessor'][i]

    text  = ''
    attrs = {}

    case model_data['Encoding'][i]

      when 'list', 'item as list'

        list_element = LibXML::XML::Node.new(model_data['REST Attribute'][i])

        attrs.each do |key,value|
          list_element[key] = value
        end

        collection = eval("ob.#{model_data['Accessor'][i]}")

        collection = [collection] if model_data['Encoding'][i] == 'item as list'

        # filter out things that the user cannot see
        collection = collection.select do |c|
          not c.respond_to?('contribution') or Authorization.is_authorized?("view", nil, c, user)
        end

        collection.each do |item|

          item_attrs = { }

          item_uri = rest_resource_uri(item)
          item_attrs['resource'] = item_uri if item_uri
          item_attrs['uri'] = rest_access_uri(item)

          list_element_accessor = model_data['List Element Accessor'][i]
          list_element_text     = list_element_accessor ? eval("item.#{model_data['List Element Accessor'][i]}") : item

          if list_element_text.instance_of?(String)
            el = LibXML::XML::Node.new(model_data['List Element Name'][i])

            item_attrs.each do |key,value|
              el[key] = value
            end

            el << list_element_text.to_s if list_element_text

            list_element << el
          else
            list_element << rest_reference(list_element_text, query)
          end
        end

        list_element

      when 'xml'

        if query['version'] and model_data['Versioned'][i] == 'yes'
          text = eval("ob.versions[#{(query['version'].to_i - 1).to_s}].#{accessor}")
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

        item = eval("ob.#{model_data['Accessor'][i]}")

        if item != nil
          resource_uri = rest_resource_uri(item)
          el['resource'] = resource_uri if resource_uri
          el['uri'] = rest_access_uri(item)
          el << item.label if item.label
        end

        el

      else 

        if model_data['Encoding'][i] == 'file-column'

          text = file_column_url(ob, model_data['Accessor'][i])

        else

          if accessor
            if query['version'] and model_data['Versioned'][i] == 'yes'
              text = eval("ob.versions[#{(query['version'].to_i - 1).to_s}].#{accessor}").to_s
            else
              text = eval("ob.#{accessor}").to_s
            end
          end

          if model_data['Encoding'][i] == 'base64'
            text = Base64.encode64(text)
            attrs = { 'type' => 'binary', 'encoding' => 'base64' }
          end

          if model_data['Foreign Accessor'][i]
            foreign_ob = eval("ob.#{model_data['Foreign Accessor'][i]}")
            if foreign_ob != nil
              resource_uri = rest_resource_uri(foreign_ob)
              attrs['resource'] = resource_uri if resource_uri
              attrs['uri'] = rest_access_uri(foreign_ob)
            end
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

def rest_get_request(ob, req_uri, user, uri, entity_name, query)

  if query['version']
    return rest_response(400) unless ob.respond_to?('versions')
    return rest_response(404) if query['version'].to_i < 1
    return rest_response(404) if ob.versions[query['version'].to_i - 1].nil?
  end

  elements = query['elements'] ? query['elements'].split(',') : nil

  doc  = LibXML::XML::Document.new()
  root = LibXML::XML::Node.new(entity_name)
  doc.root = root

  root['uri'        ] = rest_access_uri(ob)
  root['resource'   ] = uri if uri
  root['api-version'] = API_VERSION if query['api_version'] == 'yes'

  if ob.respond_to?('versions')
    if query['version']
      root['version'] = query['version']
    else
      root['version'] = ob.current_version.to_s
    end
  end

  data = TABLES['REST'][:data][req_uri]['GET']

  rest_entity = data['REST Entity']

  TABLES['Model'][:data][rest_entity]['REST Attribute'].each do |rest_attribute|
    data = rest_get_element(ob, user, rest_entity, rest_attribute, query, elements)
    root << data unless data.nil?
  end

  render(:xml => doc.to_s)
end

def rest_crud_request(req_uri, rules, user, query)

  rest_name  = rules['REST Entity']
  model_name = rules['Model Entity']

  ob = eval(model_name.camelize).find_by_id(params[:id].to_i)

  return rest_response(404) if ob.nil?

  perm_ob = ob

  perm_ob = ob.send(rules['Permission object']) if rules['Permission object']

  case rules['Permission']
    when 'public'; # do nothing
    when 'view';  return rest_response(401) if not Authorization.is_authorized?("show", nil, perm_ob, user)
    when 'owner'; return rest_response(401) if logged_in?.nil? or object_owner(perm_ob) != user
  end

  rest_get_request(ob, params[:uri], user, eval("rest_resource_uri(ob)"), rest_name, query)
end

def find_paginated_auth(args, num, page, filters, user, &blk)

  def aux(args, num, page, filters, user)

    results = yield(args, num, page)

    return nil if results.nil?

    failures = 0

    results.select do |result|

      selected = Authorization.is_authorized?('view', nil, result, user)

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

  # 'upto' is the number of results needed to fulfil the request

  upto = num * page

  results = []
  current_page = 1

  # if this isn't the first page, do a single request to fetch all the pages
  # up to possibly fulfil the request

  if (page > 1)
    results = aux(args, upto, 1, filters, user, &blk)
    current_page = page + 1
  end

  while (results.length < upto)

    results_page = aux(args, num, current_page, filters, user, &blk)

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

def rest_index_request(req_uri, rules, user, query)

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
      find_args[:page] = { :size => size, :current => page }

      results = eval(args[:model]).find(:all, find_args)

      results unless results.page > results.page_count
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

  elements = query['elements'] ? query['elements'].split(',') : nil

  obs.each do |ob|

    el = rest_reference(ob, query, !elements.nil?)

    if elements

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

  render(:xml => doc.to_s)
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

  case ob.class.to_s
    when 'Workflow';               return workflow_url(ob)
    when 'Blob';                   return file_url(ob)
    when 'Network';                return group_url(ob)
    when 'User';                   return user_url(ob)
    when 'Review';                 return workflow_review_url(ob.reviewable, ob)
    when 'Comment';                return "#{rest_resource_uri(ob.commentable)}/comments/#{ob.id}"
    when 'Bookmark';               return nil
    when 'Blog';                   return blog_url(ob)
    when 'BlogPost';               return blog_post_url(ob.blog, ob)
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
    when 'PackContributableEntry'; return rest_resource_uri(ob.contributable)
    when 'PackRemoteEntry';        return ob.uri
    when 'ContentType';            return nil
    when 'License';                return license_url(ob)

    when 'Creditation';     return nil
    when 'Attribution';     return nil
    when 'Tagging';         return nil

    when 'Workflow::Version'; return "#{rest_resource_uri(ob.workflow)}?version=#{ob.version}"
  end

  raise "Class not processed in rest_resource_uri: #{ob.class.to_s}"
end

def rest_access_uri(ob)

  base = "#{request.protocol}#{request.host_with_port}"

  case ob.class.to_s
    when 'Workflow';               return "#{base}/workflow.xml?id=#{ob.id}"
    when 'Blob';                   return "#{base}/file.xml?id=#{ob.id}"
    when 'Network';                return "#{base}/group.xml?id=#{ob.id}"
    when 'User';                   return "#{base}/user.xml?id=#{ob.id}"
    when 'Review';                 return "#{base}/review.xml?id=#{ob.id}"
    when 'Comment';                return "#{base}/comment.xml?id=#{ob.id}"
    when 'Bookmark';               return "#{base}/favourite.xml?id=#{ob.id}"
    when 'Blog';                   return "#{base}/blog.xml?id=#{ob.id}"
    when 'BlogPost';               return "#{base}/blog-post.xml?id=#{ob.id}"
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

    when 'Creditation';     return "#{base}/credit.xml?id=#{ob.id}"
    when 'Attribution';     return nil

    when 'Workflow::Version'; return "#{base}/workflow.xml?id=#{ob.workflow.id}&version=#{ob.version}"
  end

  raise "Class not processed in rest_access_uri: #{ob.class.to_s}"
end

def rest_object_tag_text(ob)

  case ob.class.to_s
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
    when 'Workflow::Version';      return 'workflow'
    when 'Comment';                return 'comment'
    when 'Bookmark';               return 'favourite'
    when 'ContentType';            return 'type'
    when 'License';                return 'license'
  end

  return 'object'
end

def rest_object_label_text(ob)

  case ob.class.to_s
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
    when 'Workflow::Version';      return ob.title
    when 'ContentType';            return ob.title
    when 'License';                return ob.title
  end

  return ''
end

def rest_reference(ob, query, skip_text = false)

  el = LibXML::XML::Node.new(rest_object_tag_text(ob))

  resource_uri = rest_resource_uri(ob)

  el['resource'] = resource_uri if resource_uri
  el['uri'     ] = rest_access_uri(ob)
  el['version' ] = ob.current_version.to_s if ob.respond_to?('current_version')

  el << rest_object_label_text(ob) if !skip_text

  el
end

def parse_resource_uri(str)

  base_uri = URI.parse("#{Conf.base_uri}/")
  uri      = base_uri.merge(str)
  is_local = base_uri.host == uri.host and base_uri.port == uri.port

  return [Workflow, $1, is_local]       if uri.path =~ /^\/workflows\/([\d]+)$/
  return [Blob, $1, is_local]           if uri.path =~ /^\/files\/([\d]+)$/
  return [Network, $1, is_local]        if uri.path =~ /^\/groups\/([\d]+)$/
  return [User, $1, is_local]           if uri.path =~ /^\/users\/([\d]+)$/
  return [Review, $1, is_local]         if uri.path =~ /^\/[^\/]+\/[\d]+\/reviews\/([\d]+)$/
  return [Comment, $1, is_local]        if uri.path =~ /^\/[^\/]+\/[\d]+\/comments\/([\d]+)$/
  return [Blog, $1, is_local]           if uri.path =~ /^\/blogs\/([\d]+)$/
  return [BlogPost, $1, is_local]       if uri.path =~ /^\/blogs\/[\d]+\/blog_posts\/([\d]+)$/
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

  nil

end

def get_resource_from_uri(uri, user)

  cl, id, local = parse_resource_uri(uri)

  return nil if cl.nil? || local == false

  resource = cl.find_by_id(id)

  return nil if !Authorization.is_authorized?('view', nil, resource, user)

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
    return nil if !Authorization.is_authorized?(permission, nil, resource, user)
  end

  resource
end

def obtain_rest_resource(type, id, version, user, permission = nil)

  resource = eval(type).find_by_id(id)

  if resource.nil?
    rest_response(404)
    return nil
  end

  if version
    if resource.versions.last.version != version.to_i
      resource = resource.find_version(version)
    end
  end

  if resource.nil?
    rest_response(404)
    return nil
  end

  if permission
    if !Authorization.is_authorized?(permission, nil, resource, user)
      rest_response(401)
      return nil
    end
  end

  resource
end

def rest_access_redirect(req_uri, rules, user, query)

  return rest_response(400) if query['resource'].nil?

  bits = parse_resource_uri(query['resource'])

  return rest_response(404) if bits.nil?

  ob = bits[0].find_by_id(bits[1])

  return rest_response(404) if ob.nil?

  return rest_response(401) if !Authorization.is_authorized?('view', nil, ob, user)

  rest_response(307, :location => rest_access_uri(ob))
end

def create_default_policy(user)
  Policy.new(:contributor => user, :name => 'auto', :share_mode => 7, :update_mode => 6)
end

def update_permissions(ob, permissions)

  share_mode  = 7
  update_mode = 6

  # clear out any permission records for this contributable

  ob.contribution.policy.permissions.each do |p|
    p.destroy
  end

  # process permission elements

  if permissions
    permissions.find('permission').each do |permission|

      # handle public privileges

      if permission.find_first('category/text()').to_s == 'public'

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
      end
    end
  end

  ob.contribution.policy.update_attributes(:share_mode => share_mode,
      :update_mode => update_mode)
end

def workflow_aux(action, req_uri, rules, user, query)

  # Obtain object

  case action
    when 'create':
      return rest_response(401) unless Authorization.is_authorized_for_type?('create', 'Workflow', user, nil)
      if query['id']
        ob = obtain_rest_resource('Workflow', query['id'], query['version'], user, action)
      else
        ob = Workflow.new(:contributor => user)
      end
    when 'read', 'update', 'destroy':
      ob = obtain_rest_resource('Workflow', query['id'], query['version'], user, action)
    else
      raise "Invalid action '#{action}'"
  end

  return if ob.nil? # appropriate rest response already given

  if action == "destroy"

    return rest_response(400, :reason => "Cannot delete individual versions") if query['version']
      
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
    revision_comment = parse_element(data, :text,   '/workflow/revision-comment')

    permissions  = data.find_first('/workflow/permissions')

    # build the contributable

    ob.title        = title        if title
    ob.body         = description  if description
    ob.license      = License.find_by_unique_name(license_type) if license_type

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

    # Handle the preview and svg images.  If there's a preview supplied, use
    # it.  Otherwise auto-generate one if we can.

    if preview.nil? and content
      metadata = Workflow.extract_metadata(:type => ob.content_type.title, :data => content)
      preview = metadata["image"].read if metadata["image"]
    end

    if preview

      image = Tempfile.new('image')
      image.write(preview)
      image.rewind

      image.extend FileUpload
      image.original_filename = 'preview'
      
      ob.image = image

      image.close
    end

    success = if (action == 'create' and query['id'])
      ob.save_as_new_version(revision_comment)
    else
      ob.save
    end

    return rest_response(400, :object => ob) unless success

    # Elements to update if we're not dealing with a workflow version

    if query['version'].nil?

      if ob.contribution.policy.nil?
        ob.contribution.policy = create_default_policy(user)
        ob.contribution.save
      end

      update_permissions(ob, permissions)
    end
  end

  ob = ob.versioned_resource if ob.respond_to?("versioned_resource")

  rest_get_request(ob, "workflow", user,
      rest_resource_uri(ob), "workflow", { "id" => ob.id.to_s })
end

def post_workflow(req_uri, rules, user, query)
  workflow_aux('create', req_uri, rules, user, query)
end

def put_workflow(req_uri, rules, user, query)
  workflow_aux('update', req_uri, rules, user, query)
end

def delete_workflow(req_uri, rules, user, query)
  workflow_aux('destroy', req_uri, rules, user, query)
end

# file handling

def file_aux(action, req_uri, rules, user, query)

  # Obtain object

  case action
    when 'create':
      return rest_response(401) unless Authorization.is_authorized_for_type?('create', 'Blob', user, nil)
      ob = Blob.new(:contributor => user)
    when 'read', 'update', 'destroy':
      ob = obtain_rest_resource('Blob', query['id'], query['version'], user, action)
    else
      raise "Invalid action '#{action}'"
  end

  return if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    data = LibXML::XML::Parser.string(request.raw_post).parse

    title        = parse_element(data, :text,   '/file/title')
    description  = parse_element(data, :text,   '/file/description')
    license_type = parse_element(data, :text,   '/file/license-type')
    type         = parse_element(data, :text,   '/file/type')
    content_type = parse_element(data, :text,   '/file/content-type')
    content      = parse_element(data, :binary, '/file/content')

    permissions  = data.find_first('/file/permissions')

    # build the contributable

    ob.title        = title        if title
    ob.body         = description  if description

    if license_type
      ob.license = License.find_by_unique_name(license_type)
      if ob.license.nil?
        ob.errors.add("License type")
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

    if not ob.save
      return rest_response(400, :object => ob)
    end

    if ob.contribution.policy.nil?
      ob.contribution.policy = create_default_policy(user)
      ob.contribution.save
    end

    update_permissions(ob, permissions)
  end

  rest_get_request(ob, "file", user,
      rest_resource_uri(ob), "file", { "id" => ob.id.to_s })
end

def post_file(req_uri, rules, user, query)
  file_aux('create', req_uri, rules, user, query)
end

def put_file(req_uri, rules, user, query)
  file_aux('update', req_uri, rules, user, query)
end

def delete_file(req_uri, rules, user, query)
  file_aux('destroy', req_uri, rules, user, query)
end

# def post_job(req_uri, rules, user, query)
#
#   title       = params["job"]["title"]
#   description = params["job"]["description"]
#
#   experiment_bits = parse_resource_uri(params["job"]["experiment"])
#   runner_bits     = parse_resource_uri(params["job"]["runner"])
#   runnable_bits   = parse_resource_uri(params["job"]["runnable"])
#
#   return rest_response(400) if title.nil?
#   return rest_response(400) if description.nil?
#
#   return rest_response(400) if experiment_bits.nil? or experiment_bits[0] != 'Experiment'
#   return rest_response(400) if runner_bits.nil?     or runner_bits[0]     != 'TavernaEnactor'
#   return rest_response(400) if runnable_bits.nil?   or runnable_bits[0]   != 'Workflow'
#
#   experiment = Experiment.find_by_id(experiment_bits[1].to_i)
#   runner     = TavernaEnactor.find_by_id(runner_bits[1].to_i)
#   runnable   = Workflow.find_by_id(runnable_bits[1].to_i)
#
#   return rest_response(400) if experiment.nil? or not Authorization.is_authorized?('edit', nil, experiment, user)
#   return rest_response(400) if runner.nil?     or not Authorization.is_authorized?('download', nil, runner, user)
#   return rest_response(400) if runnable.nil?   or not Authorization.is_authorized?('view', nil, runnable, user)
#
#   puts "#{params[:job]}"
#
#   job = Job.new(:title => title, :description => description, :runnable => runnable, 
#       :experiment => experiment, :runner => runner, :user => user,
#       :runnable_version => runnable.current_version)
#
#   inputs = { "Tags" => "aa,bb,aa,cc,aa" }
#
#   job.inputs_data = inputs
#
#   success = job.submit_and_run!
#
#   return rest_response(500) if not success
#
#   return "<yes/>"
#
# end

def paginated_search_index(query, models, num, page, user)

  return [] if not Conf.solr_enable or query.nil? or query == ""

  find_paginated_auth( { :query => query, :models => models }, num, page, [], user) { |args, size, page|

    q      = args[:query]
    models = args[:models]

    search_result = models[0].multi_solr_search(q, :limit => size, :offset => size * (page - 1), :models => models)
    search_result.results unless search_result.total < (size * (page - 1))
  }
end

def search(req_uri, rules, user, query)

  search_query = query['query']

  models = [User, Workflow, Blob, Network, Pack]

  # parse type option

  if query['type']

    models = []

    query['type'].split(',').each do |type|
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

  if query['num']
    num = query['num'].to_i
  end

  num = 25  if num < 0
  num = 100 if num > 100

  page  = query['page'] ? query['page'].to_i : 1

  page = 1 if page < 1

  attributes = {}
  attributes['query'] = search_query
  attributes['type'] = query['type'] if models.length == 1

  obs = paginated_search_index(search_query, models, num, page, user)

  produce_rest_list(req_uri, rules, query, obs, 'search', attributes, user)
end

def user_count(req_uri, rules, user, query)
  
  users = User.find(:all).select do |user| user.activated? end

  root = LibXML::XML::Node.new('user-count')
  root << users.length.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  render(:xml => doc.to_s)
end

def group_count(req_uri, rules, user, query)
  
  root = LibXML::XML::Node.new('group-count')
  root << Network.count.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  render(:xml => doc.to_s)
end

def workflow_count(req_uri, rules, user, query)
  
  workflows = Workflow.find(:all).select do |w|
    Authorization.is_authorized?('view', nil, w, user)
  end

  root = LibXML::XML::Node.new('workflow-count')
  root << workflows.length.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  render(:xml => doc.to_s)
end

def pack_count(req_uri, rules, user, query)
  
  packs = Pack.find(:all).select do |p|
    Authorization.is_authorized?('view', nil, p, user)
  end

  root = LibXML::XML::Node.new('pack-count')
  root << packs.length.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  render(:xml => doc.to_s)
end

def content_type_count(req_uri, rules, user, query)

  root = LibXML::XML::Node.new('type-count')
  root << ContentType.count.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  render(:xml => doc.to_s)
end

def get_tagged(req_uri, rules, user, query)

  return rest_response(400) if query['tag'].nil?

  tag = Tag.find_by_name(query['tag'])

  obs = tag ? tag.tagged : []

  # filter out ones they are not allowed to get
  obs = (obs.select do |c| c.respond_to?('contribution') == false or Authorization.is_authorized?("index", nil, c, user) end)

  produce_rest_list("tagged", rules, query, obs, 'tagged', [], user)
end

def tag_cloud(req_uri, rules, user, query)

  num  = 25
  type = nil

  if query['num']
    if query['num'] == 'all'
      num = nil
    else
      num = query['num'].to_i
    end
  end

  if query['type'] and query['type'] != 'all'
    type = query['type'].camelize

    type = 'Network' if type == 'Group'
    type = 'Blob'    if type == 'File'
  end

  tags = Tag.find_by_tag_count(num, type)

  doc = LibXML::XML::Document.new()

  root = LibXML::XML::Node.new('tag-cloud')
  doc.root = root

  root['type'] = query['type'] ? query['type'] : 'all'

  tags.each do |tag|
    tag_node = rest_reference(tag, query)
    tag_node['count'] = tag.taggings_count.to_s
    root << tag_node
  end

  render(:xml => doc.to_s)
end

def whoami_redirect(req_uri, rules, user, query)
  if user.class == User
    rest_response(307, :location => rest_access_uri(user))
  else
    rest_response(401)
  end
end

def parse_element(doc, kind, query)
  case kind
    when :text
      el = doc.find_first("#{query}/text()")
      return el.to_s if el
    when :binary
      el = doc.find_first("#{query}/text()")
      return Base64::decode64(el.to_s) if el
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
    if Authorization.is_authorized?(type, nil, ob, user) 
      privilege = LibXML::XML::Node.new('privilege')
      privilege['type'] = type

      privileges << privilege
    end
  end

  privileges
end

# Comments

def comment_aux(action, req_uri, rules, user, query)

  # Obtain object

  case action
    when 'create':
      return rest_response(401) unless Authorization.is_authorized_for_type?('create', 'Comment', user, nil)

      ob = Comment.new(:user => user)
    when 'read', 'update', 'destroy':
      ob = obtain_rest_resource('Comment', query['id'], query['version'], user, action)
    else
      raise "Invalid action '#{action}'"
  end

  return if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    data = LibXML::XML::Parser.string(request.raw_post).parse

    comment = parse_element(data, :text,     '/comment/comment')
    subject = parse_element(data, :resource, '/comment/subject')

    ob.comment = comment if comment

    if subject
      return rest_response(400) unless [Blob, Network, Pack, Workflow].include?(subject.class)
      return rest_response(401) unless Authorization.is_authorized_for_type?(action, 'Comment', user, subject)
      ob.commentable = subject
    end

    return rest_response(400, :object => ob) unless ob.save
  end

  rest_get_request(ob, "comment", user, rest_resource_uri(ob), "comment", { "id" => ob.id.to_s })
end

def post_comment(req_uri, rules, user, query)
  comment_aux('create', req_uri, rules, user, query)
end

def put_comment(req_uri, rules, user, query)
  comment_aux('update', req_uri, rules, user, query)
end

def delete_comment(req_uri, rules, user, query)
  comment_aux('destroy', req_uri, rules, user, query)
end

# Favourites

def favourite_aux(action, req_uri, rules, user, query)

  # Obtain object

  case action
    when 'create':
      return rest_response(401) unless Authorization.is_authorized_for_type?('create', 'Bookmark', user, nil)

      ob = Bookmark.new(:user => user)
    when 'read', 'update', 'destroy':
      ob = obtain_rest_resource('Bookmark', query['id'], query['version'], user, action)
    else
      raise "Invalid action '#{action}'"
  end

  return if ob.nil? # appropriate rest response already given

  if action == "destroy"

    ob.destroy

  else

    data = LibXML::XML::Parser.string(request.raw_post).parse

    target = parse_element(data, :resource, '/favourite/object')

    if target
      return rest_response(400) unless [Blob, Pack, Workflow].include?(target.class)
      return rest_response(401) unless Authorization.is_authorized_for_type?(action, 'Bookmark', user, target)
      ob.bookmarkable = target
    end

    return rest_response(400, :object => ob) unless ob.save
  end

  rest_get_request(ob, "favourite", user, rest_resource_uri(ob), "favourite", { "id" => ob.id.to_s })
end

def post_favourite(req_uri, rules, user, query)
  favourite_aux('create', req_uri, rules, user, query)
end

def put_favourite(req_uri, rules, user, query)
  favourite_aux('update', req_uri, rules, user, query)
end

def delete_favourite(req_uri, rules, user, query)
  favourite_aux('destroy', req_uri, rules, user, query)
end

# Call dispatcher

def rest_call_request(req_uri, rules, user, query)
  eval("#{rules['Function']}(req_uri, rules, user, query)")
end

