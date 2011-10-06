# myExperiment: app/controllers/application.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  filter_parameter_logging :password
  
  WhiteListHelper.tags.merge %w(table tr td th div span)
  
  before_filter :set_configuration

  include AuthenticatedSystem
  before_filter :login_from_cookie
  before_filter :oauth_required
  
  include ActionView::Helpers::NumberHelper

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_m2_session_id'
  
  def base_host
    request.host_with_port
  end
  
  
  # if "referer" in the HTTP header contains "myexperiment", we know
  # that current action was accessed from myExperiment website; if
  # referer is not set OR doesn't contain the search string, access
  # was initiated from other location 
  def accessed_from_website?
    res = false
    
    referer = request.env['HTTP_REFERER']
    unless referer.nil? || referer.match("^#{Conf.base_uri}").nil?
      res = true
    end
    
    return res
  end

  def set_configuration
    Conf.set_configuration(request, session)
  end

  def formatted_timespan(time_period)
    # Takes a period of time in seconds and returns it in human-readable form (down to minutes)
    # from (http://www.postal-code.com/binarycode/category/devruby/)
    out_str = ""
        
    interval_array = [ [:weeks, 604800], [:days, 86400], [:hours, 3600], [:minutes, 60] ]
    interval_array.each do |sub|
      if time_period >= sub[1]
        time_val, time_period = time_period.divmod(sub[1])
            
        time_val == 1 ? name = sub[0].to_s.singularize : name = sub[0].to_s
              
        ( sub[0] != :minutes ? out_str += ", " : out_str += " and " ) if out_str != ''
        out_str += time_val.to_s + " #{name}"
      end
    end
   
    return out_str  
  end
  
  
  # this method is only intended to check if entry
  # in "viewings" or "downloads" table needs to be
  # created for current access - and this is *only*
  # supposed to be working for *contributables*
  #
  # NB! The input parameter is the actual contributable OR
  # the version of it (currently only workflows are versioned)
  def allow_statistics_logging(contributable_or_version)
    
    # check if the current viewing/download is to be logged
    # (i.e. request is sent not by a bot and is legitimate)
    allow_logging = true
    Conf.bot_ignore_list.each do |pattern|
      if request.env['HTTP_USER_AGENT'] and request.env['HTTP_USER_AGENT'].match(pattern)
        allow_logging = false
        break
      end
    end
    
    # disallow logging of events referring to contributables / versions of them
    # that have been uploaded by current user; 
    #
    # however, if there are newer versions of contributable (uploaded not by the original uploader),
    # we do want to record viewings/downloads of this newer version by the original uploader  
    if allow_logging && current_user != 0
      allow_logging = false if (contributable_or_version.contributor_type == "User" && contributable_or_version.contributor_id == current_user.id)
    end
    
    return allow_logging
  end
  
  
  # Safe HTML - http://www.anyexample.com/webdev/rails/how_to_allow_some_safe_html_in_rails_projects.xml
  # Note: should only be used for text that doesn't need updating later.
  def ae_some_html(s)
    return '' if s.nil?    
    
    # converting newlines
    s.gsub!(/\r\n?/, "\n")
 
    # escaping HTML to entities
    s = s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
 
    # blockquote tag support
    s.gsub!(/\n?&lt;blockquote&gt;\n*(.+?)\n*&lt;\/blockquote&gt;/im, "<blockquote>\\1</blockquote>")
 
    # other tags: b, i, em, strong, u
    %w(b i em strong u).each { |x|
         s.gsub!(Regexp.new('&lt;(' + x + ')&gt;(.+?)&lt;/('+x+')&gt;',
                 Regexp::MULTILINE|Regexp::IGNORECASE), 
                 "<\\1>\\2</\\1>")
        }
 
    # A tag support
    # href="" attribute auto-adds http://
    s = s.gsub(/&lt;a.+?href\s*=\s*['"](.+?)["'].*?&gt;(.+?)&lt;\/a&gt;/im) { |x|
            '<a href="' + ($1.index('://') ? $1 : 'http://'+$1) + "\">" + $2 + "</a>"
          }
 
    # replacing newlines to <br> ans <p> tags
    # wrapping text into paragraph
    s = "<p>" + s.gsub(/\n\n+/, "</p>\n\n<p>").
            gsub(/([^\n]\n)(?=[^\n])/, '\1<br />') + "</p>"
 
    s      
  end
  
  # This method takes a comma seperated list of tags (where multiple words don't need to be in quote marks)
  # and formats it into a new comma seperated list where multiple words ARE in quote marks.
  # (Note: it will actually put quote marks around all the words and then out commas).
  # eg: 
  #    this, is a, tag
  #        becomes:
  #    "this","is a","tag"
  #
  # This is so we can map the tags entered in by users to the format required by the act_as_taggable_redux gem.
  def convert_tags_to_gem_format(tags_string)
    list = parse_comma_seperated_string(tags_string)
    converted = '' 
    
    list.each do |s|
      converted = converted + '"' + s.strip + '",'
    end
    
    return converted
  end
  
  helper_method :ae_some_html
  
  # This method converts a comma seperated string of values into a collection of those values.
  # Note: currently does not cater for values in quotation marks and does not remove empty values
  # (although it does ignore a trailing comma)
  def parse_comma_seperated_string(s)
    list = s.split(',')
  end

  def update_policy(contributable, params)

    # this method will return an error message is something goes wrong (empty string in case of success)
    error_msg = ""
    

    # BEGIN validation and initialisation
    
    # This variable will hold current settings of the policy in case something
    # goes wrong and a revert would be needed at some point
    last_saved_policy = nil
    
    return if params[:sharing].nil? or params[:sharing][:class_id].blank?
    
    sharing_class  = params[:sharing][:class_id]
    updating_class = (params[:updating] and !params[:updating][:class_id].blank?) ? params[:updating][:class_id] : "6"
    
    # Check allowed sharing_class values
    return unless [ "0", "1", "2", "3", "4", "7" ].include? sharing_class
    
    # Check allowed updating_class values
    return unless [ "0", "1", "5", "6" ].include? updating_class
    
    view_protected     = 0
    view_public        = 0
    download_protected = 0
    download_public    = 0
    edit_protected     = 0
    edit_public        = 0
    
    # BEGIN initialisation and validation

    unless contributable.contribution.policy
      last_saved_policy = Policy._default(current_user, nil) # second parameter ensures that this policy is not applied anywhere
      
      policy = Policy.new(:name => 'auto',
          :contributor_type => 'User', :contributor_id => current_user.id,
          :share_mode         => sharing_class,
          :update_mode        => updating_class)
      contributable.contribution.policy = policy  # by doing this the new policy object is saved implicitly too
      contributable.contribution.save
    else
       policy = contributable.contribution.policy
       last_saved_policy = policy.clone # clone required, not 'dup' (which still works through reference, so the values in both get changed anyway - which is not what's needed here)
       
       policy.share_mode = sharing_class
       policy.update_mode = updating_class
       policy.save
    end


    # Process 'update' permissions for "Some of my Friends"

    if updating_class == "5"
      if params[:updating_somefriends]
        # Delete old User permissions
        policy.delete_all_user_permissions
        
        # Now create new User permissions, if required
        params[:updating_somefriends].each do |f|
          Permission.new(:policy => policy,
              :contributor => (User.find f[1].to_i),
              :view => 1, :download => 1, :edit => 1).save
        end
      else # none of the 'some of my friends' were selected, error
        # revert changes made to policy (however any permissions updated will preserve the state)
        policy.copy_values_from( last_saved_policy )
        policy.save
        error_msg += "You have selected to set 'update' permissions for 'Some of your Friends', but didn't select any from the list.</br>Previous (if any) or default sharing permissions have been set."
        return error_msg
      end
    else
      # Delete all User permissions - as this isn't mode 5 (i.e. the mode has changed),
      # where some explicit permissions to friends are set
      policy.delete_all_user_permissions
    end
    
    
    # Process explicit Group permissions now
    if params[:group_sharing]
      
      # First delete any Permission objects that don't have a checked entry in the form
      policy.permissions.each do |p|
        params[:group_sharing].each do |n|
          # If a hash value with key 'id' wasn't returned then that means the checkbox was unchecked.
          unless n[1][:id]
            if p.contributor_type == 'Network' and p.contributor_id == n[0].to_i
              p.destroy
            end
          end
        end
      end
    
      # Now create or update Permissions
      params[:group_sharing].each do |n|
        
        # Note: n[1] is used because n is an array and n[1] returns it's value (which in turn is a hash)
        # In this hash, is a value with key 'id' is present then the checkbox for that group was checked.
        if n[1][:id]
          
          n_id = n[1][:id].to_i
          level = n[1][:level]
          
          unless (perm = Permission.find(:first, :conditions => ["policy_id = ? AND contributor_type = ? AND contributor_id = ?", policy.id, 'Network', n_id]))
            # Only create new Permission if it doesn't already exist
            p = Permission.new(:policy => policy, :contributor => (Network.find(n_id)))
            p.set_level!(level) if level
          else
            # Update the 'level' on the existing permission
            perm.set_level!(level) if level
          end
          
        else
          
          n_id = n[0].to_i
          
          # Delete permission if it exists (because this one is unchecked)
          if (perm = Permission.find(:first, :conditions => ["policy_id = ? AND contributor_type = ? AND contributor_id = ?", policy.id, 'Network', n_id]))
            perm.destroy
          end
          
        end
      
      end
    end

    logger.debug("------ Workflow create summary ------------------------------------")
    logger.debug("current_user   = #{current_user.id}")
    logger.debug("updating_class = #{updating_class}")
    logger.debug("sharing_class  = #{sharing_class}")
    logger.debug("policy         = #{policy}")
    logger.debug("group_sharing  = #{params[:group_sharing]}")
    logger.debug("-------------------------------------------------------------------")

    # returns some message in case of errors (or empty string in case of success)
    return error_msg
  end

  def update_credits(creditable, params)
    
    # First delete old creditations:
    creditable.creditors.each do |c|
      c.destroy
    end
    
    # Then create new creditations:
    
    # Current user
    if (params[:credits_me].downcase == 'true')
      c = Creditation.new(:creditor_type => 'User', :creditor_id => current_user.id, :creditable_type => creditable.class.to_s, :creditable_id => creditable.id)
      c.save
    end
    
    # Friends + other users
    user_ids = parse_comma_seperated_string(params[:credits_users])
    user_ids.each do |id|
      c = Creditation.new(:creditor_type => 'User', :creditor_id => id, :creditable_type => creditable.class.to_s, :creditable_id => creditable.id)
      c.save
    end
    
    # Networks (aka Groups)
    network_ids = parse_comma_seperated_string(params[:credits_groups])
    network_ids.each do |id|
      c = Creditation.new(:creditor_type => 'Network', :creditor_id => id, :creditable_type => creditable.class.to_s, :creditable_id => creditable.id)
      c.save
    end
    
  end
  
  def update_attributions(attributable, params)
    
    # First delete old attributions:
    attributable.attributors.each do |a|
      a.destroy
    end
    
    # Then create new attributions:
    
    # Workflows
    attributor_workflow_ids = parse_comma_seperated_string(params[:attributions_workflows])
    attributor_type = 'Workflow'
    attributor_workflow_ids.each do |id|
      a = Attribution.new(:attributor_type => attributor_type, :attributor_id => id, :attributable_type => attributable.class.to_s, :attributable_id  => attributable.id)
      a.save
    end
    
    # Files
    attributor_file_ids = parse_comma_seperated_string(params[:attributions_files])
    attributor_type = 'Blob'
    attributor_file_ids.each do |id|
      a = Attribution.new(:attributor_type => attributor_type, :attributor_id => id, :attributable_type => attributable.class.to_s, :attributable_id  => attributable.id)
      a.save
    end
    
  end
 
  # helper function to determine the context of a polymorphic nested resource

  def extract_resource_context(params)
    (Conf.contributor_models + Conf.contributable_models).each do |model_name|
      id_param = "#{Conf.to_visible(model_name.underscore)}_id"
      return Object.const_get(model_name).find_by_id(params[id_param]) if params[id_param]
    end

    nil
  end 

  def deep_clone(ob)
    case ob.class.name
    when "Array"
      ob.map do |x| deep_clone(x) end
    when "Hash"
      hash = {}
      ob.each do |k, v| hash[deep_clone(k)] = deep_clone(v) end
      hash
    when "Symbol"
      ob
    else
      ob.clone
    end
  end

  def send_cached_data(file_name, *opts)

    if !File.exists?(file_name)
      FileUtils.mkdir_p(File.dirname(file_name))
      File.open(file_name, "wb+") { |f| f.write(yield) }
    end

    send_file(file_name, *opts)
  end

  # Pivot code
  
  def pivot_options
    {
      :order => 
      [
        {
          :option => 'rank',
          :label  => 'Rank',
          :order  => 'contributions.rank DESC'
        },
        
        {
          :option => 'title',
          :label  => 'Title',
          :order  => 'contributions.label, contributions.rank DESC'
        },

        {
          :option => 'latest',
          :label  => 'Latest',
          :order  => 'contributions.created_at DESC, contributions.rank DESC'
        },

        {
          :option => 'last_updated',
          :label  => 'Last updated',
          :order  => 'contributions.updated_at DESC, contributions.rank DESC'
        },

        {
          :option => 'rating',
          :label  => 'Community rating',
          :order  => 'contributions.rating DESC, contributions.rank DESC'
        },

        {
          :option => 'viewings',
          :label  => 'Most viewed',
          :order  => 'contributions.site_viewings_count DESC, contributions.rank DESC'
        },

        {
          :option => 'downloads',
          :label  => 'Most downloaded',
          :order  => 'contributions.site_downloads_count DESC, contributions.rank DESC'
        },

        {
          :option => 'type',
          :label  => 'Type',
          :joins  => [ :content_types ],
          :order  => 'content_types.title, contributions.rank DESC'
        },

        {
          :option => 'licence',
          :label  => 'Licence',
          :joins  => [ :licences ],
          :order  => 'licenses.title, contributions.rank DESC'
        },

        {
          :option => 'topic',
          :label  => 'Topic',
          :joins  => [ :topic_workflow_map ],
          :order  => 'topic_workflow_map.probability, rank DESC'
        }
      ],

      :num_options => ['10', '20', '25', '50', '100'],

      :filters =>
      [
        {
          :title        => 'category',
          :query_option => 'CATEGORY',
          :id_column    => :auth_type,
          :label_column => :auth_type,
          :visible_name => true
        },

        {
          :title        => 'type',
          :query_option => 'TYPE_ID',
          :id_column    => 'content_types.id',
          :label_column => 'content_types.title',
          :joins        => [ :content_types ],
          :not_null     => true
        },

        {
          :title        => 'tag',
          :query_option => 'TAG_ID',
          :id_column    => 'tags.id',
          :label_column => 'tags.name',
          :joins        => [ :taggings, :tags ]
        },

        {
          :title        => 'user',
          :query_option => 'USER_ID',
          :id_column    => 'users.id',
          :label_column => 'users.name',
          :joins        => [ :users ]
        },

        {
          :title        => 'licence',
          :query_option => 'LICENSE_ID',
          :id_column    => 'licenses.id',
          :label_column => 'licenses.unique_name',
          :joins        => [ :licences ],
          :not_null     => true
        },

        {
          :title        => 'group',
          :query_option => 'GROUP_ID',
          :id_column    => 'networks.id',
          :label_column => 'networks.title',
          :joins        => [ :networks ]
        },

        {
          :title        => 'wsdl',
          :query_option => 'WSDL_ENDPOINT',
          :id_column    => 'workflow_processors.wsdl',
          :label_column => 'workflow_processors.wsdl',
          :joins        => [ :workflow_processors ],
          :not_null     => true
        },

        {
          :title        => 'curation',
          :query_option => 'CURATION_EVENT',
          :id_column    => 'curation_events.category',
          :label_column => 'curation_events.category',
          :joins        => [ :curation_events ],
          :capitalize   => true
        },

        {
          :title        => 'country',
          :query_option => 'SERVICE_COUNTRY',
          :id_column    => 'services.country',
          :label_column => 'services.country',
          :joins        => [ :services ]
        },

        {
          :title        => 'provider',
          :query_option => 'SERVICE_PROVIDER',
          :id_column    => 'service_providers.id',
          :label_column => 'service_providers.name',
          :joins        => [ :services, :service_providers ]
        },

        {
          :title        => 'service status',
          :query_option => 'SERVICE_STATUS',
          :id_column    => 'services.monitor_label',
          :label_column => 'services.monitor_label',
          :joins        => [ :services ]
        },


      ],

      :joins =>
      {
        :content_types       => "LEFT OUTER JOIN content_types ON contributions.content_type_id = content_types.id",
        :licences            => "LEFT OUTER JOIN licenses ON contributions.license_id = licenses.id",
        :users               => "INNER JOIN users ON contributions.contributor_type = 'User' AND contributions.contributor_id = users.id",
        :taggings            => "LEFT OUTER JOIN taggings ON AUTH_TYPE = taggings.taggable_type AND AUTH_ID = taggings.taggable_id",
        :tags                => "INNER JOIN tags ON taggings.tag_id = tags.id",
        :networks            => "INNER JOIN networks ON permissions.contributor_type = 'Network' AND permissions.contributor_id = networks.id",
        :credits             => "INNER JOIN creditations ON creditations.creditable_type = AUTH_TYPE AND creditations.creditable_id = AUTH_ID",
        :curation_events     => "INNER JOIN curation_events ON curation_events.object_type = AUTH_TYPE AND curation_events.object_id = AUTH_ID",
        :workflow_processors => "INNER JOIN workflow_processors ON AUTH_TYPE = 'Workflow' AND workflow_processors.workflow_id = AUTH_ID",
        :search              => "RIGHT OUTER JOIN search_results ON search_results.result_type = AUTH_TYPE AND search_results.result_id = AUTH_ID",
        :topic_workflow_map  => "INNER JOIN topic_workflow_map ON contributions.id = topic_workflow_map.workflow_id",
        :services            => "INNER JOIN services ON AUTH_TYPE = 'Service' AND AUTH_ID = services.id",
        :service_providers   => "INNER JOIN service_providers ON AUTH_TYPE = 'Service' AND service_providers.uri = services.provider_uri",
      }
    }
  end

  TOKEN_UNKNOWN         = 0x0000
  TOKEN_AND             = 0x0001
  TOKEN_OR              = 0x0002
  TOKEN_WORD            = 0x0003
  TOKEN_OPEN            = 0x0004
  TOKEN_CLOSE           = 0x0005
  TOKEN_STRING          = 0x0006
  TOKEN_EOS             = 0x00ff

  NUM_TOKENS            = 6

  STATE_INITIAL         = 0x0000
  STATE_EXPECT_OPEN     = 0x0100
  STATE_EXPECT_STR      = 0x0200
  STATE_EXPECT_EXPR_END = 0x0300
  STATE_EXPECT_END      = 0x0400
  STATE_COMPLETE        = 0x0500

  def parse_filter_expression(expr)

    def unescape_string(str)
      str.match(/^"(.*)"$/)[1].gsub(/\\"/, '"')
    end

    state  = STATE_INITIAL
    data   = []

    begin

      tokens = expr.match(/^

          \s* (\sAND\s)         | # AND operator
          \s* (\sOR\s)          | # OR operator
          \s* (\w+)             | # a non-keyword word
          \s* (\()              | # an open paranthesis
          \s* (\))              | # a close paranthesis
          \s* ("(\\.|[^\\"])*")   # double quoted string with backslash escapes

          /ix)

      if tokens.nil?
        token = TOKEN_UNKNOWN
      else
        (1..NUM_TOKENS).each do |i|
          token = i if tokens[i]
        end
      end

      if token == TOKEN_UNKNOWN
        token = TOKEN_EOS if expr.strip.empty?
      end

      case state | token
        when STATE_INITIAL         | TOKEN_WORD   : state = STATE_EXPECT_OPEN     ; data << { :name => tokens[0], :expr => [] }
        when STATE_EXPECT_OPEN     | TOKEN_OPEN   : state = STATE_EXPECT_STR
        when STATE_EXPECT_STR      | TOKEN_STRING : state = STATE_EXPECT_EXPR_END ; data.last[:expr] << tokens[0] 
        when STATE_EXPECT_EXPR_END | TOKEN_AND    : state = STATE_EXPECT_STR      ; data.last[:expr] << :and 
        when STATE_EXPECT_EXPR_END | TOKEN_OR     : state = STATE_EXPECT_STR      ; data.last[:expr] << :or 
        when STATE_EXPECT_EXPR_END | TOKEN_CLOSE  : state = STATE_EXPECT_END
        when STATE_EXPECT_END      | TOKEN_AND    : state = STATE_INITIAL         ; data << :and 
        when STATE_EXPECT_END      | TOKEN_OR     : state = STATE_INITIAL         ; data << :or 
        when STATE_EXPECT_END      | TOKEN_EOS    : state = STATE_COMPLETE

        else raise "Error parsing query expression"
      end

      expr = tokens.post_match unless state == STATE_COMPLETE

    end while state != STATE_COMPLETE

    # validate and reduce expressions to current capabilities

    valid_filters = pivot_options[:filters].map do |f| f[:query_option] end

    data.each do |category|
      case category
      when :or
        raise "Unsupported query expression"
      when :and
        # Fine
      else
        raise "Unknown filter category" unless valid_filters.include?(category[:name])

        counts = { :and => 0, :or => 0 }

        category[:expr].each do |bit|
          counts[bit] = counts[bit] + 1 if bit.class == Symbol
        end

        raise "Unsupported query expression" if counts[:and] > 0 && counts[:or] > 0

        # haven't implemented 'and' within a particular filter yet
        raise "Unsupported query expression" if counts[:and] > 0

        if category[:expr].length == 1
          category[:expr] = { :terms => [unescape_string(category[:expr].first)] }
        else
          category[:expr] = {
            :operator => category[:expr][1],
            :terms    => category[:expr].select do |t|
              t.class == String
            end.map do |t|
              unescape_string(t)
            end
          }
        end
      end
    end

    data
  end

  def contributions_list(klass = nil, params = nil, user = nil, opts = {})

    def escape_sql(str)
      str.gsub(/\\/, '\&\&').gsub(/'/, "''")
    end

    def build_url(params, opts, expr, parts, extra = {})

      query = {}

      if parts.include?(:filter)
        bits = []
        pivot_options[:filters].each do |filter|
          if !opts[:lock_filter] || opts[:lock_filter][filter[:query_option]].nil?
            if find_filter(expr, filter[:query_option])
              bits << filter[:query_option] + "(\"" + find_filter(expr, filter[:query_option])[:expr][:terms].map do |t| t.gsub(/"/, '\"') end.join("\" OR \"") + "\")"
            end
          end
        end

        if bits.length > 0
          query["filter"] = bits.join(" AND ")
        end
      end

      query["query"]        = params[:query]        if params[:query]
      query["order"]        = params[:order]        if parts.include?(:order)
      query["filter_query"] = params[:filter_query] if parts.include?(:filter_query)

      query.merge!(extra)

      query
    end

    def comparison(lhs, rhs)
      if rhs.length == 1
        "#{lhs} = '#{escape_sql(rhs.first)}'"
      else
        "#{lhs} IN ('#{rhs.map do |bit| escape_sql(bit) end.join("', '")}')"
      end
    end

    def create_search_results_table(search_query, models)

      solr_results = models.first.multi_solr_search(search_query,
          :models         => models,
          :results_format => :ids,
          :limit          => Conf.max_search_size)

      conn =  ActiveRecord::Base.connection

      conn.execute("CREATE TEMPORARY TABLE search_results (id INT AUTO_INCREMENT UNIQUE KEY, result_type VARCHAR(255), result_id INT)")

      # This next part converts the search results to SQL values
      #
      # from:  { "id" => "Workflow:4" }, { "id" => "Pack:6" }, ...
      # to:    "(NULL, 'Workflow', '4'), (NULL, 'Pack', '6'), ..."

      if solr_results.results.length > 0
        insert_part = solr_results.results.map do |result|
          "(NULL, " + result["id"].split(":").map do |bit|
            "'#{bit}'"
          end.join(", ") + ")"
        end.join(", ")
 
        conn.execute("INSERT INTO search_results VALUES #{insert_part}")
      end
    end

    def drop_search_results_table
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS search_results")
    end

    def calculate_having_clause(filter, opts)

      having_bits = []

      pivot_options[:filters].each do |f|
        if f != filter
#         if opts[:filters][f[:query_option]] && opts[:filters]["and_#{f[:query_option]}"] == "yes"
#           having_bits << "(GROUP_CONCAT(DISTINCT #{f[:id_column]} ORDER BY #{f[:id_column]}) = '#{escape_sql(opts[:filters][f[:query_option]])}')"
#         end
        end
      end

      return nil if having_bits.empty?

      "HAVING " + having_bits.join(" OR ")
    end

    def column(column, opts)
      if column == :auth_type
        if opts[:auth_type]
          opts[:auth_type]
        else
          "contributions.contributable_type"
        end
      else
        column
      end
    end

    def calculate_filter(params, filter, user, opts = {})

      # apply all the joins and conditions except for the current filter

      joins      = []
      conditions = []

      pivot_options[:filters].each do |other_filter|
        if filter_list = find_filter(opts[:filters], other_filter[:query_option])
          unless opts[:inhibit_other_conditions]
            conditions << comparison(column(other_filter[:id_column], opts), filter_list[:expr][:terms]) unless other_filter == filter
          end
          joins += other_filter[:joins] if other_filter[:joins]
        end
      end

      filter_id_column    = column(filter[:id_column],    opts)
      filter_label_column = column(filter[:label_column], opts)

      joins += filter[:joins] if filter[:joins]
      conditions << "#{filter_id_column} IS NOT NULL" if filter[:not_null]

      unless opts[:inhibit_filter_query]
        if params[:filter_query]
          conditions << "(#{filter_label_column} LIKE '%#{escape_sql(params[:filter_query])}%')"
        end
      end

      joins.push(:search) if params[:query] && !opts[:arbitrary_models]

      current = find_filter(opts[:filters], filter[:query_option]) ? find_filter(opts[:filters], filter[:query_option])[:expr][:terms] : []

      if opts[:ids].nil?
        limit = 10
      else
        conditions << "(#{filter_id_column} IN ('#{opts[:ids].map do |id| escape_sql(id) end.join("','")}'))"
        limit = nil
      end

      conditions = conditions.length.zero? ? nil : conditions.join(" AND ")

      if opts[:auth_type] && opts[:auth_id]
        count_expr = "COUNT(DISTINCT #{opts[:auth_type]}, #{opts[:auth_id]})"
      else
        count_expr = "COUNT(DISTINCT contributions.contributable_type, contributions.contributable_id)"
      end

      objects = Authorization.authorised_index(params[:query] && opts[:arbitrary_models] ? SearchResult : Contribution,
          :all,
          :include_permissions => true,
          :select => "#{filter_id_column} AS filter_id, #{filter_label_column} AS filter_label, #{count_expr} AS filter_count",
          :arbitrary_models => opts[:arbitrary_models],
          :auth_type => opts[:auth_type],
          :auth_id => opts[:auth_id],
          :joins => merge_joins(joins, :auth_type => opts[:auth_type], :auth_id => opts[:auth_id]),
          :conditions => conditions,
          :group => "#{filter_id_column} #{calculate_having_clause(filter, opts)}",
          :limit => limit,
          :order => "#{count_expr} DESC, #{filter_label_column}",
          :authorised_user => user)
      
      objects = objects.select do |x| !x[:filter_id].nil? end

      objects = objects.map do |object|

        value = object.filter_id.to_s
        selected = current.include?(value)

        label_expr = deep_clone(opts[:filters])
        label_expr -= [find_filter(label_expr, filter[:query_option])] if find_filter(label_expr, filter[:query_option])

        unless selected && current.length == 1
          label_expr << { :name => filter[:query_option], :expr => { :terms => [value] } }
        end

        checkbox_expr = deep_clone(opts[:filters])

        if expr_filter = find_filter(checkbox_expr, filter[:query_option])

          if selected
            expr_filter[:expr][:terms] -= [value]
          else
            expr_filter[:expr][:terms] += [value]
          end

          checkbox_expr -= [expr_filter] if expr_filter[:expr][:terms].empty?

        else
          checkbox_expr << { :name => filter[:query_option], :expr => { :terms => [value] } }
        end

        label_uri = build_url(params, opts, label_expr, [:filter, :order], "page" => nil)

        checkbox_uri = build_url(params, opts, checkbox_expr, [:filter, :order], "page" => nil)

        label = object.filter_label.clone
        label = visible_name(label) if filter[:visible_name]
        label = label.capitalize    if filter[:capitalize]

        plain_label = object.filter_label

        if params[:filter_query]
          label.sub!(Regexp.new("(#{params[:filter_query]})", Regexp::IGNORECASE), '<b>\1</b>')
        end

        {
          :object       => object,
          :value        => value,
          :label        => label,
          :plain_label  => plain_label,
          :count        => object.filter_count,
          :checkbox_uri => checkbox_uri,
          :label_uri    => label_uri,
          :selected     => selected
        }
      end

      [current, objects]
    end

    def calculate_filters(params, opts, user)

      # produce the filter list

      filters = pivot_options[:filters].clone
      cancel_filter_query_url = nil

      filters.each do |filter|

        # calculate the top n items of the list

        filter[:current], filter[:objects] = calculate_filter(params, filter, user, opts)

        # calculate which active filters are missing (because they weren't in the
        # top part of the list or have a count of zero)

        missing_filter_ids = filter[:current] - filter[:objects].map do |ob| ob[:value] end

        if missing_filter_ids.length > 0
          filter[:objects] += calculate_filter(params, filter, user, opts.merge(:ids => missing_filter_ids))[1]
        end

        # calculate which active filters are still missing (because they have a
        # count of zero)

        missing_filter_ids = filter[:current] - filter[:objects].map do |ob| ob[:value] end
        
        if missing_filter_ids.length > 0
          zero_list = calculate_filter(params, filter, user, opts.merge(:ids => missing_filter_ids, :inhibit_other_conditions => true))[1]

          zero_list.each do |x| x[:count] = 0 end

          zero_list.sort! do |a, b| a[:label] <=> b[:label] end

          filter[:objects] += zero_list
        end
      end

      [filters, cancel_filter_query_url]
    end

    def find_filter(filters, name)
      filters.find do |f|
        f[:name] == name
      end
    end

    def merge_joins(joins, opts = {})

      opts[:auth_type] ||= 'contributions.contributable_type'
      opts[:auth_id]   ||= 'contributions.contributable_id'

      if joins.length.zero?
        nil
      else
        joins.uniq.map do |j|
          text = pivot_options[:joins][j]
          text.gsub!(/AUTH_TYPE/, opts[:auth_type])
          text.gsub!(/AUTH_ID/,   opts[:auth_id])
          text
        end.join(" ")
      end
    end

    joins      = []
    conditions = []

    # parse the filter expression if provided.  convert filter expression to
    # the old format.  this will need to be replaced eventually

    opts[:filters] ||= []
    
    include_reset_url = opts[:filters].length > 0

    # filter out top level logic operators for now

    opts[:filters] = opts[:filters].select do |bit|
      bit.class == Hash
    end

    # apply locked filters

    if opts[:lock_filter]
      opts[:lock_filter].each do |filter, value|
        opts[:filters] << { :name => filter, :expr => { :terms => [value] } }
      end
    end

    # perform search if requested

    group_by = "contributions.contributable_type, contributions.contributable_id"

    if params["query"]
      drop_search_results_table
      create_search_results_table(params["query"], [Workflow, Blob, Pack, User, Network, Service])
      joins.push(:search) unless opts[:arbitrary_models]
    end

    if opts[:arbitrary_models] && params[:query]
      klass = SearchResult
      contribution_records = false
      auth_type = "search_results.result_type"
      auth_id   = "search_results.result_id"
      group_by  = "search_results.result_type, search_results.result_id"
    else
      contribution_records = true
    end

    # determine joins, conditions and order for the main results

    pivot_options[:filters].each do |filter|
      if filter_list = find_filter(opts[:filters], filter[:query_option])
        conditions << comparison(column(filter[:id_column], opts.merge( { :auth_type => auth_type, :auth_id => auth_id } )), filter_list[:expr][:terms])
        joins += filter[:joins] if filter[:joins]
      end
    end

    order_options = pivot_options[:order].find do |x|
      x[:option] == params[:order]
    end

    order_options ||= pivot_options[:order].first

    joins += order_options[:joins] if order_options[:joins]

    having_bits = []

#   pivot_options[:filters].each do |filter|
#     if params["and_#{filter[:query_option]}"]
#       having_bits << "GROUP_CONCAT(DISTINCT #{filter[:id_column]} ORDER BY #{filter[:id_column]}) = \"#{escape_sql(opts[:filters][filter[:query_option]])}\""
#     end
#   end

    having_clause = ""

    if having_bits.length > 0
      having_clause = "HAVING #{having_bits.join(' AND ')}"
    end

    # perform the results query

    results = Authorization.authorised_index(klass,
        :all,
        :authorised_user => user,
        :include_permissions => true,
        :contribution_records => contribution_records,
        :arbitrary_models => opts[:arbitrary_models],
        :auth_type => auth_type,
        :auth_id => auth_id,
        :page => { :size => params["num"] ? params["num"].to_i : nil, :current => params["page"] },
        :joins => merge_joins(joins, :auth_type => auth_type, :auth_id => auth_id),
        :conditions => conditions.length.zero? ? nil : conditions.join(" AND "),
        :group => "#{group_by} #{having_clause}",
        :order => order_options[:order])

    # produce a query hash to match the current filters

    opts[:filter_params] = {}

    pivot_options[:filters].each do |filter|
      if params[filter[:query_option]]
        next if opts[:lock_filter] && opts[:lock_filter][filter[:query_option]]
        opts[:filter_params][filter[:query_option]] = params[filter[:query_option]]
      end
    end

    # produce the filter list

    opts_for_filter_query = opts.merge( { :auth_type => auth_type,
        :auth_id => auth_id, :group_by => group_by } )

    filters, cancel_filter_query_url = calculate_filters(params, opts_for_filter_query, user)

    # produce the summary.  If a filter query is specified, then we need to
    # recalculate the filters without the query to get all of them.

    if params[:filter_query]
      filters2 = calculate_filters(params, opts_for_filter_query.merge( { :inhibit_filter_query => true } ), user)[0]
    else
      filters2 = filters
    end

    summary = ""

    filters2.select do |filter|

      next if opts[:lock_filter] && opts[:lock_filter][filter[:query_option]]

      selected = filter[:objects].select do |x| x[:selected] end
      current  = selected.map do |x| x[:value] end

      if selected.length > 0
        selected_labels = selected.map do |x|

          expr = deep_clone(opts[:filters])

          f = find_filter(expr, filter[:query_option])
  
          expr -= f[:expr][:terms] -= [x[:value]]
          expr -= [f] if f[:expr][:terms].empty?

          x[:plain_label] + ' <a href="' + url_for(build_url(params, opts, expr,
          [:filter, :filter_query, :order])) +
            '">' + " <img src='/images/famfamfam_silk/cross.png' /></a>"

        end

        bits = selected_labels.map do |label| label end.join(" <i>or</i> ")

        summary << '<span class="filter-in-use"><b>' + filter[:title].capitalize + "</b>: " + bits + "</span> "
      end
    end

    if params[:filter_query]
      cancel_filter_query_url = build_url(params, opts, opts[:filters], [:filter, :order])
    end

    if include_reset_url
      reset_filters_url = build_url(params, opts, opts[:filters], [:order])
    end

    # remove filters that do not help in narrowing down the result set

    filters = filters.select do |filter|
      if filter[:objects].empty?
        false
      elsif opts[:lock_filter] && opts[:lock_filter][filter[:query_option]]
        false
      else
        true
      end
    end

    {
      :results                 => results,
      :filters                 => filters,
      :reset_filters_url       => reset_filters_url,
      :cancel_filter_query_url => cancel_filter_query_url,
      :filter_query_url        => build_url(params, opts, opts[:filters], [:filter]),
      :summary                 => summary
    }
  end
end

