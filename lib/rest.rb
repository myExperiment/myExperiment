# myExperiment: lib/rest.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'lib/excel_xml'
require 'xml/libxml'
require 'uri'

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

  fields = (field.split('/').map do |f| "'#{f}'" end).join(', ')

  path = eval("ActionView::Base.new.url_for_file_column(ob, #{fields})")

  "#{request.protocol}#{request.host_with_port}#{path}"
end

def rest_get_request(ob, req_uri, uri, entity_name, query)

  if query['version']
    return rest_error_response(400, 'Resource not versioned') unless ob.respond_to?('versions')
    return rest_error_response(404, 'Resource version not found') if query['version'].to_i < 1
    return rest_error_response(404, 'Resource version not found') if ob.versions[query['version'].to_i - 1].nil?
  end

  elements = query['elements'] ? query['elements'].split(',') : nil

  doc  = XML::Document.new()
  root = XML::Node.new(entity_name)
  doc.root = root

  root['uri'        ] = rest_access_uri(ob)
  root['resource'   ] = uri
  root['api-version'] = API_VERSION if query['api_version'] == 'yes'

  if ob.respond_to?('versions')
    if query['version']
      root['version'] = query['version']
    else
      root['version'] = ob.versions.last.version.to_s
    end
  end

  data = TABLES['REST'][:data][req_uri]['GET']

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

      unless accessor.nil? or model_data['Encoding'][i] == 'file-column'
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
        list_element = XML::Node.new(model_data['REST Attribute'][i])

        attrs.each do |key,value|
          list_element[key] = value
        end

        root << list_element

        collection = eval("ob.#{model_data['Accessor'][i]}")

        # filter out things that the user cannot see
        collection = collection.select do |c|
          not c.respond_to?('contribution') or c.authorized?('view', current_user)
        end

        collection.each do |item|

          item_attrs = { }

          item_uri = rest_resource_uri(item)
          item_attrs['resource'] = item_uri if item_uri
          item_attrs['uri'] = rest_access_uri(item)

          list_element_accessor = model_data['List Element Accessor'][i]
          list_element_text     = list_element_accessor ? eval("item.#{model_data['List Element Accessor'][i]}") : item

          if list_element_text.instance_of?(String)
            el = XML::Node.new(model_data['List Element Name'][i])

            item_attrs.each do |key,value|
              el[key] = value
            end

            el << list_element_text.to_s if list_element_text

            list_element << el
          else
            list_element << rest_reference(list_element_text, query)
          end
        end

      else

        if model_data['Foreign Accessor'][i]
          attrs['resource'] = eval("rest_resource_uri(ob.#{model_data['Foreign Accessor'][i]})")
          attrs['uri'] = eval("rest_access_uri(ob.#{model_data['Foreign Accessor'][i]})")
        end

#        puts "ATTRIBUTE = #{model_data['REST Attribute'][i]}, ATTRS = #{attrs.inspect}, text = #{text.inspect}"

        el = XML::Node.new(model_data['REST Attribute'][i])

        attrs.each do |key,value|
          el[key] = value
        end

        el << text
        root << el
      end
    end
  end

  doc
end

def rest_error_response(code, message)

  error = XML::Node.new('error')
  error["code"   ] = code.to_s
  error["message"] = message

  doc = XML::Document.new
  doc.root = error

  doc
end

def rest_crud_request(rules)

  query = CGIMethods.parse_query_parameters(request.query_string)

  rest_name  = rules['REST Entity']
  model_name = rules['Model Entity']

  ob = eval(model_name.camelize).find_by_id(params[:id].to_i)

  return rest_error_response(404, 'Resource not found') if ob.nil?

  perm_ob = ob

  perm_ob = ob.send(rules['Permission object']) if rules['Permission object']

  case rules['Permission']
    when 'public'; # do nothing
    when 'view'; return rest_error_response(403, 'Not authorized') if not perm_ob.authorized?("show", (logged_in? ? current_user : nil))
    when 'owner'; return rest_error_response(403, 'Not authorized') if logged_in?.nil? or object_owner(perm_ob) != current_user
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

    find_args = { :page => part, :order => "#{sort} #{order}" }

    find_args[:conditions] = conditions if conditions

    obs = eval(model_name.camelize).find(:all, find_args)
  end

  # filter out ones they are not allowed to get
  obs = (obs.select do |c| c.respond_to?('contribution') == false or c.authorized?("index", (logged_in? ? current_user : nil)) end)

  produce_rest_list(rules, query, obs, rest_name.pluralize)
end

def produce_rest_list(rules, query, obs, tag)

  root = XML::Node.new(tag)

  root['api-version'] = API_VERSION if query['api_version'] == 'yes'

  obs.map do |ob|
    root << rest_reference(ob, query)
  end

  doc = XML::Document.new
  doc.root = root

  doc
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
    when 'Workflow';       return workflow_url(ob)
    when 'Blob';           return file_url(ob)
    when 'Network';        return group_url(ob)
    when 'User';           return user_url(ob)
    when 'Review';         return review_url(ob.reviewable, ob)
    when 'Comment';        return "#{rest_resource_uri(ob.commentable)}/comments/#{ob.id}"
    when 'Blog';           return blog_url(ob)
    when 'BlogPost';       return blog_post_url(ob.blog, ob)
    when 'Rating';         return "#{rest_resource_uri(ob.rateable)}/ratings/#{ob.id}"
    when 'Tag';            return tag_url(ob)
    when 'Picture';        return picture_url(ob.owner, ob)
    when 'Message';        return message_url(ob)
    when 'Citation';       return citation_url(ob.workflow, ob)
    when 'Announcement';   return announcement_url(ob)
    when 'Pack';           return pack_url(ob)
    when 'Experiment';     return experiment_url(ob)
    when 'TavernaEnactor'; return runner_url(ob)
    when 'Job';            return experiment_job_url(ob.experiment, ob)

    when 'Workflow::Version'; "#{rest_resource_uri(ob.workflow)}?version=#{ob.version}"
  end
end

def rest_access_uri(ob)

  base = "#{request.protocol}#{request.host_with_port}"

  case ob.class.to_s
    when 'Workflow';       return "#{base}/workflow.xml?id=#{ob.id}"
    when 'Blob';           return "#{base}/file.xml?id=#{ob.id}"
    when 'Network';        return "#{base}/group.xml?id=#{ob.id}"
    when 'User';           return "#{base}/user.xml?id=#{ob.id}"
    when 'Review';         return "#{base}/review.xml?id=#{ob.id}"
    when 'Comment';        return "#{base}/comment.xml?id=#{ob.id}"
    when 'Blog';           return "#{base}/blog.xml?id=#{ob.id}"
    when 'BlogPost';       return "#{base}/blog-post.xml?id=#{ob.id}"
    when 'Rating';         return "#{base}/rating.xml?id=#{ob.id}"
    when 'Tag';            return "#{base}/tag.xml?id=#{ob.id}"
    when 'Picture';        return "#{base}/picture.xml?id=#{ob.id}"
    when 'Message';        return "#{base}/message.xml?id=#{ob.id}"
    when 'Citation';       return "#{base}/citation.xml?id=#{ob.id}"
    when 'Announcement';   return "#{base}/announcement.xml?id=#{ob.id}"
    when 'Pack';           return "#{base}/pack.xml?id=#{ob.id}"
    when 'Experiment';     return "#{base}/experiment.xml?id=#{ob.id}"
    when 'TavernaEnactor'; return "#{base}/runner.xml?id=#{ob.id}"
    when 'Job';            return "#{base}/job.xml?id=#{ob.id}"

    when 'Workflow::Version'; return "#{base}/workflow.xml?id=#{ob.workflow.id}&version=#{ob.version}"
  end
end

def rest_reference(ob, query)

  tag  = 'object'
  text = ''

  case ob.class.to_s
    when 'User';         tag = 'user';         text = ob.name
    when 'Workflow';     tag = 'workflow';     text = ob.title
    when 'Blob';         tag = 'file';         text = ob.title
    when 'Network';      tag = 'group';        text = ob.title
    when 'Rating';       tag = 'rating';       text = ob.rating.to_s
    when 'Creditation';  tag = 'creditation';  text = ''
    when 'Citation';     tag = 'citation';     text = ob.title
    when 'Announcement'; tag = 'announcement'; text = ob.title
    when 'Tag';          tag = 'tag';          text = ob.name
    when 'Pack';         tag = 'pack';         text = ob.title
    when 'Experiment';   tag = 'experiment';   text = ob.title

    when 'Workflow::Version'; tag = 'workflow'; text = ob.title
  end

  el = XML::Node.new(tag)
  el['resource'] = rest_resource_uri(ob)
  el['uri'     ] = rest_access_uri(ob)
  el['version' ] = ob.version.to_s if ob.respond_to?('version')
  el << text

  el
end

def parse_resource_uri(str)

  base_uri = URI.parse("#{request.protocol}#{request.host_with_port}/")
  uri      = base_uri.merge(str)
  is_local = base_uri.host == uri.host and base_uri.port == uri.port

  return ["Workflow", $1, is_local]      if uri.path =~ /^\/workflows\/([\d]+)$/
  return ["Blob", $1, is_local]          if uri.path =~ /^\/files\/([\d]+)$/
  return ["Network", $1, is_local]       if uri.path =~ /^\/groups\/([\d]+)$/
  return ["User", $1, is_local]          if uri.path =~ /^\/users\/([\d]+)$/
  return ["Review", $1, is_local]        if uri.path =~ /^\/[^\/]+\/[\d]+\/reviews\/([\d]+)$/
  return ["Comment", $1, is_local]       if uri.path =~ /^\/[^\/]+\/[\d]+\/comments\/([\d]+)$/
  return ["Blog", $1, is_local]          if uri.path =~ /^\/blogs\/([\d]+)$/
  return ["BlogPost", $1, is_local]      if uri.path =~ /^\/blogs\/[\d]+\/blog_posts\/([\d]+)$/
  return ["Tag", $1, is_local]           if uri.path =~ /^\/tags\/([\d]+)$/
  return ["Picture", $1, is_local]       if uri.path =~ /^\/users\/[\d]+\/pictures\/([\d]+)$/
  return ["Message", $1, is_local]       if uri.path =~ /^\/messages\/([\d]+)$/
  return ["Citation", $1, is_local]      if uri.path =~ /^\/[^\/]+\/[\d]+\/citations\/([\d]+)$/
  return ["Announcement", $1, is_local]  if uri.path =~ /^\/announcements\/([\d]+)$/
  return ["Pack", $1, is_local]          if uri.path =~ /^\/packs\/([\d]+)$/
  return ["Experiment", $1, is_local]    if uri.path =~ /^\/experiments\/([\d]+)$/
  return ["Runner", $1, is_local]        if uri.path =~ /^\/runners\/([\d]+)$/
  return ["Job", $1, is_local]           if uri.path =~ /^\/jobs\/([\d]+)$/

  nil

end

def get_rest_uri(rules, query)

  return bad_rest_request if query['resource'].nil?

  obs = (obs.select do |c| c.respond_to?('contribution') == false or c.authorized?("index", (logged_in? ? current_user : nil)) end)
  doc = REXML::Document.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?><rest-uri/>")
  "bing"
end

def create_default_policy
  Policy.new(:name => 'auto', :update_mode => 6, :share_mode => 0,
      :view_public     => true,  :view_protected     => false,
      :download_public => true,  :download_protected => false,
      :edit_public     => false, :edit_protected     => false,
      :contributor => current_user)
end

def post_workflow(rules, query)

  return rest_error_response(400, 'Bad Request') if current_user == 0

  title        = params["workflow"]["title"]
  description  = params["workflow"]["description"]
  license_type = params["workflow"]["license_type"]
  content_type = params["workflow"]["content_type"]
  content      = params["workflow"]["content"]

  return rest_error_response(400, 'Bad Request') if title.nil?
  return rest_error_response(400, 'Bad Request') if description.nil?
  return rest_error_response(400, 'Bad Request') if license_type.nil?
  return rest_error_response(400, 'Bad Request') if content_type.nil?
  return rest_error_response(400, 'Bad Request') if content.nil?
  
  content = Base64.decode64(content)

  contibution = Contribution.new(
      :policy           => create_default_policy,
      :contributor_type => 'User',
      :contributor_id   => current_user.id)

  workflow = Workflow.new(
      :title            => title,
      :body             => description,
      :license          => license_type,
      :content_type     => content_type,
      :scufl            => content,
      :contributor_type => 'User',
      :contributor_id   => current_user.id,
      :contribution     => contibution)

  scufl_model = Scufl::Parser.new.parse(content)

  workflow.create_workflow_diagrams(scufl_model, "1")

  if not workflow.save
    return rest_error_response(400, 'Bad Request') if description.nil?
  end

  workflow.contribution.update_attributes( {
      :contributor_type => 'User', :contributor_id => current_user.id } )

  workflow.contribution.policy = create_default_policy
  workflow.contribution.save

  rest_get_request(workflow, "workflow",
      rest_resource_uri(workflow), "workflow", { "id" => workflow.id.to_s })
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
    results = models[0].multi_solr_search(search_query, :limit => 100,
        :models => models).results
  end

  root = XML::Node.new('search')
  root['query'] = search_query
  root['type' ] = query['type'] if query['type']

  results.each do |result|
    root << rest_reference(result, query)
  end

  doc = XML::Document.new
  doc.root = root
  doc
end

def user_count(rules, query)
  
  users = User.find(:all).select do |user| user.activated? end

  root = XML::Node.new('user-count')
  root << users.length.to_s

  doc = XML::Document.new
  doc.root = root

  doc
end

def group_count(rules, query)
  
  groups = Network.find(:all)

  root = XML::Node.new('group-count')
  root << groups.length.to_s

  doc = XML::Document.new
  doc.root = root
  doc
end

def get_tagged(rules, query)

  return rest_error_response(400, 'Bad Request') if query['tag'].nil?

  tag = Tag.find_by_name(query['tag'])

  obs = tag ? tag.tagged : []

  # filter out ones they are not allowed to get
  obs = (obs.select do |c| c.respond_to?('contribution') == false or c.authorized?('index', (logged_in? ? current_user : nil)) end)

  produce_rest_list(rules, query, obs, 'tagged')
end

def tag_cloud(rules, query)

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

  doc = XML::Document.new()

  root = XML::Node.new('tag-cloud')
  doc.root = root

  root['type'] = query['type'] ? query['type'] : 'all'

  tags.each do |tag|
    tag_node = rest_reference(tag, query)
    tag_node['count'] = tag.taggings_count.to_s
    root << tag_node
  end

  doc
end

def post_comment(rules, query)

  title    = params[:comment][:title]
  text     = params[:comment][:comment]
  resource = params[:comment][:resource]

  title = '' if title.nil?

  resource_bits = parse_resource_uri(params["comment"]["resource"])

  return rest_error_response(400, 'Bad Request') if current_user == 0
  return rest_error_response(400, 'Bad Request') if text.nil? or text.length.zero?
  return rest_error_response(400, 'Bad Request') if resource_bits.nil?

  return rest_error_response(400, 'Bad Request') unless ['Blob', 'Network', 'Pack', 'Workflow'].include?(resource_bits[0])

  resource = eval(resource_bits[0]).find_by_id(resource_bits[1].to_i)

  comment = Comment.create(:user => current_user, :comment => text)
  resource.comments << comment

  rest_get_request(comment, "comment", rest_resource_uri(comment), "comment", { "id" => comment.id.to_s })
end

def rest_call_request(rules, query)
  eval("#{rules['Function']}(rules, query)")
end

