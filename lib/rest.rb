# myExperiment: lib/rest.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'lib/excel_xml'

API_VERSION = "0.1"

TABLES = parse_excel_2003_xml(File.read('config/tables.xml'),

  { 'Model' => { :indices => [ 'REST Entity' ],
                 :lists   => [ 'REST Attribute', 'Encoding', 'Accessor',
                               'Create', 'Read', 'Update', 'Read by default',
                               'Foreign Accessor',
                               'List Element Name', 'List Element Accessor',
                               'Example', 'Versioned' ] },
                
    'REST'  => { :indices => [ 'URI', 'Method' ] }
  } )

def rest_routes(map)
  TABLES['REST'][:data].keys.each do |uri|
    TABLES['REST'][:data][uri].keys.each do |method|
      map.connect "#{uri}.xml", :controller => 'api', :action => 'process_request', :uri => uri
    end
  end
end

def bad_rest_request
  render(:text => '400 Bad Request', :status => '400 Bad Request')
end

def file_column_url(ob, field)
  "#{request.protocol}#{request.host_with_port}#{ActionView::Base.new.url_for_file_column(ob, field)}"
end

def rest_get_request(ob, req_uri, uri, entity_name, query)

  if query['version']
    return rest_error_response('Resource not versioned') unless ob.respond_to?('versions')
    return rest_error_response('Version not found') if query['version'].to_i < 1
    return rest_error_response('Version not found') if ob.versions[query['version'].to_i - 1].nil?
  end

  elements = query['elements'] ? query['elements'].split(',') : nil

  doc = REXML::Document.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?><#{entity_name}/>")

  doc.root.add_attribute('uri', rest_access_uri(ob))
  doc.root.add_attribute('resource', uri)
  doc.root.add_attribute('api-version', API_VERSION) if query['api_version'] == 'yes'

  if ob.respond_to?('versions')
    if query['version']
      doc.root.add_attribute('version', query['version'])
    else
      doc.root.add_attribute('version', ob.versions.last.version.to_s)
    end
  end

  data = TABLES['REST'][:data][req_uri][request.method.to_s.upcase]

  rest_entity = data['REST Entity']

  model_data = TABLES['Model'][:data][rest_entity]

  (0...model_data['REST Attribute'].length).each do |i|

    unless query['all_elements'] == 'yes'
      next if elements and not elements.index(model_data['REST Attribute'][i])
      next if not elements and model_data['Read by default'][i] == 'no'
    end

    if (model_data['Read'][i] == 'yes')
      accessor = model_data['Accessor'][i]

      text = ''

      unless accessor.nil?
        if query['version'] and model_data['Versioned'][i] == 'yes'
          text = eval("ob.versions[#{(query['version'].to_i - 1).to_s}].#{accessor}").to_s
        else
          text = eval("ob.#{accessor}").to_s
        end
      end

      attrs = {}

      case model_data['Encoding'][i]

        when 'base64'
          text = Base64.encode64(text)
          attrs = { 'type' => 'binary', 'encoding' => 'base64' }
        when 'file-column';
          text = file_column_url(ob, model_data['Accessor'][i])
      end

      if model_data['Encoding'][i] == 'list'
        list_element = doc.root.add_element(model_data['REST Attribute'][i], attrs)

        collection = eval("ob.#{model_data['Accessor'][i]}")

        collection.each do |item|

          item_attrs = { }

          item_uri = rest_resource_uri(item)
          item_attrs['resource'] = item_uri if item_uri
          item_attrs['uri'] = rest_access_uri(item)

          list_element_accessor = model_data['List Element Accessor'][i]
          list_element_text     = list_element_accessor ? eval("item.#{model_data['List Element Accessor'][i]}") : item

          if list_element_text.instance_of?(String)
            el = list_element.add_element(model_data['List Element Name'][i], item_attrs)
            el.add_text(list_element_text.to_s) if list_element_text
          else
            list_element.add_element(rest_reference(list_element_text, query))
          end
        end

      else

        if model_data['Foreign Accessor'][i]
          attrs['resource'] = eval("rest_resource_uri(ob.#{model_data['Foreign Accessor'][i]})")
          attrs['uri'] = eval("rest_access_uri(ob.#{model_data['Foreign Accessor'][i]})")
        end

        doc.root.add_element(model_data['REST Attribute'][i], attrs).add_text(text)
      end
    end
  end

  doc
end

def rest_error_response(message)
  doc = REXML::Document.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?><error/>")
  doc.root.add_text(message)
  return doc
end

def rest_crud_request(rules)

  query = CGIMethods.parse_query_parameters(request.query_string)

  rest_name  = rules['REST Entity']
  model_name = rules['Model Entity']

  ob = eval(model_name.camelize).find_by_id(params[:id].to_i)

  return rest_error_response('Not authorized') if ob.nil?

  perm_ob = ob

  perm_ob = ob.send(rules['Permission object']) if rules['Permission object']

  case rules['Permission']
    when 'public'; # do nothing
    when 'view'; return rest_error_response('Not authorized') if not perm_ob.authorized?("show", (logged_in? ? current_user : nil))
    when 'owner'; return rest_error_response('Not authorized') if logged_in?.nil? or object_owner(perm_ob) != current_user
  end

  response.content_type = "application/xml"
  rest_get_request(ob, params[:uri], eval("rest_resource_uri(ob)"), rest_name, query)
end

def rest_index_request(rules, query)

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
  
  part = { :size => limit, :current => page }

  doc = REXML::Document.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?><#{rest_name.pluralize}/>")

  doc.root.add_attribute('api-version', API_VERSION) if query['api_version'] == 'yes'

  if query['tag']
    tag = Tag.find_by_name(query['tag'])

    if tag
      obs = (tag.taggings.select do |t| t.taggable_type == model_name.camelize end).map do |t| t.taggable end
    else
      obs = []
    end
  else

    sort  = 'id'
    order = 'ASC'

    case query['sort']
      when 'updated'; sort = 'updated_at' if eval(model_name.camelize).new.respond_to?('updated_at')
      when 'title';   sort = 'title'      if eval(model_name.camelize).new.respond_to?('title')
      when 'name';    sort = 'name'       if eval(model_name.camelize).new.respond_to?('name')
    end

    order = 'DESC' if query['order'] == 'reverse'

    obs = eval(model_name.camelize).find(:all, :page => part, :order => "#{sort} #{order}")
  end

  # filter out ones they are not allowed to get
  obs = (obs.select do |c| c.respond_to?('contribution') == false or c.authorized?("index", (logged_in? ? current_user : nil)) end)

  obs.map do |c|
    el = doc.root.add_element(rest_name, { 'resource' => eval("rest_resource_uri(c)") } )
    el.add_text(eval("c.#{rules['Element text accessor']}"))
  end

  doc
end

def object_owner(ob)
  return User.find(ob.to) if ob.class == Message
  return ob.user  if ob.respond_to?("user")
  return ob.owner if ob.respond_to?("owner")
end

def rest_resource_uri(ob)

  case ob.class.to_s
    when 'Workflow'; return workflow_url(ob)
    when 'Blob';     return file_url(ob)
    when 'Network';  return group_url(ob)
    when 'User';     return user_url(ob)
    when 'Review';   return review_url(ob.reviewable, ob)
    when 'Comment';  return "#{rest_resource_uri(ob.commentable)}/comments/#{ob.id}"
    when 'Blog';     return blog_url(ob)
    when 'BlogPost'; return blog_post_url(ob.blog, ob)
    when 'Rating';   return "#{rest_resource_uri(ob.rateable)}/ratings/#{ob.id}"
    when 'Tag';      return tag_url(ob)
    when 'Picture';  return picture_url(ob.owner, ob)
    when 'Message';  return message_url(ob)
    when 'Citation'; return citation_url(ob.workflow, ob)

    when 'Workflow::Version'; "#{rest_resource_uri(ob.workflow)}?version=#{ob.version}"
  end
end

def rest_access_uri(ob)

  base = "#{request.protocol}#{request.host_with_port}"

  case ob.class.to_s
    when 'Workflow'; return "#{base}/workflow.xml?id=#{ob.id}"
    when 'Blob';     return "#{base}/file.xml?id=#{ob.id}"
    when 'Network';  return "#{base}/group.xml?id=#{ob.id}"
    when 'User';     return "#{base}/user.xml?id=#{ob.id}"
    when 'Review';   return "#{base}/review.xml?id=#{ob.id}"
    when 'Comment';  return "#{base}/comment.xml?id=#{ob.id}"
    when 'Blog';     return "#{base}/blog.xml?id=#{ob.id}"
    when 'BlogPost'; return "#{base}/blog-post.xml?id=#{ob.id}"
    when 'Rating';   return "#{base}/rating.xml?id=#{ob.id}"
    when 'Tag';      return "#{base}/tag.xml?id=#{ob.id}"
    when 'Picture';  return "#{base}/picture.xml?id=#{ob.id}"
    when 'Message';  return "#{base}/message.xml?id=#{ob.id}"
    when 'Citation'; return "#{base}/citation.xml?id=#{ob.id}"

    when 'Workflow::Version'; return "#{base}/workflow.xml?id=#{ob.workflow.id}&version=#{ob.version}"
  end
end

def rest_reference(ob, query)

  tag  = 'object'
  text = ''

  case ob.class.to_s
    when 'User';        tag = 'user';        text = ob.name
    when 'Workflow';    tag = 'workflow';    text = ob.title
    when 'Blob';        tag = 'file';        text = ob.title
    when 'Network';     tag = 'group';       text = ob.title
    when 'Rating';      tag = 'rating';      text = ob.rating.to_s
    when 'Creditation'; tag = 'creditation'; text = ''
    when 'Citation';    tag = 'citation';    text = ob.title

    when 'Workflow::Version'; tag = 'workflow'; text = ob.title
  end

  el = REXML::Element.new(tag)
  el.add_attribute('resource', rest_resource_uri(ob))
  el.add_attribute('uri', rest_access_uri(ob))
  el.add_attribute('version', ob.version.to_s) if ob.respond_to?('version')
  el.add_text(text)

  el
end

def get_rest_uri(rules, query)

  return bad_rest_request if query['resource'].nil?

  obs = (obs.select do |c| c.respond_to?('contribution') == false or c.authorized?("index", (logged_in? ? current_user : nil)) end)
  doc = REXML::Document.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?><rest-uri/>")
  "bing"
end

def search(rules, query)

  search_query = query['query']

  models = [User, Workflow, Blob, Network]

  case query['type']
    when 'user';     models = [User]
    when 'workflow'; models = [Workflow]
    when 'file';     models = [Blob]
    when 'group';    models = [Network]
  end

  results = []

  if SOLR_ENABLE and not search_query.nil? and search_query != ""
    results = User.multi_solr_search(search_query, :limit => 100,
        :models => models).results
  end

  doc = REXML::Document.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?><search/>")
  doc.root.add_attributes( { 'query' => search_query } )
  doc.root.add_attributes( { 'type' => query['type'] } ) if query['type']

  results.each do |result|
    doc.root.add_element(rest_reference(result, query))
  end

  doc
end

def rest_call_request(rules, query)
  eval("#{rules['Function']}(rules, query)")
end

