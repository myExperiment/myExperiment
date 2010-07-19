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

  # Pivot code
  
  def pivot_options
    {
      :order => 
      [
        {
          :option => 'rank',
          :label  => 'Rank',
          :order  => 'rank DESC'
        },
        
        {
          :option => 'title',
          :label  => 'Title',
          :order  => 'label, rank DESC'
        },

        {
          :option => 'latest',
          :label  => 'Latest',
          :order  => 'created_at DESC, rank DESC'
        },

        {
          :option => 'last_updated',
          :label  => 'Last updated',
          :order  => 'updated_at DESC, rank DESC'
        },

        {
          :option => 'rating',
          :label  => 'Community rating',
          :order  => 'rating DESC, rank DESC'
        },

        {
          :option => 'viewings',
          :label  => 'Most viewed',
          :order  => 'site_viewings_count DESC, rank DESC'
        },

        {
          :option => 'downloads',
          :label  => 'Most downloaded',
          :order  => 'site_downloads_count DESC, rank DESC'
        },

        {
          :option => 'type',
          :label  => 'Type',
          :joins  => [ :content_types ],
          :order  => 'content_types.title, rank DESC'
        },

        {
          :option => 'licence',
          :label  => 'Licence',
          :joins  => [ :licences ],
          :order  => 'licenses.title, rank DESC'
        }
      ],

      :num_options => ['10', '20', '25', '50', '100'],

      :filters =>
      [
        {
          :title        => 'category',
          :query_option => 'type',
          :id_column    => 'contributions.contributable_type',
          :label_column => 'contributions.contributable_type',
          :visible_name => true
        },

        {
          :title        => 'type',
          :query_option => 'content_type',
          :id_column    => 'content_types.id',
          :label_column => 'content_types.title',
          :joins        => [ :content_types ],
          :not_null     => true
        },

        {
          :title        => 'tag',
          :query_option => 'tag',
          :id_column    => 'tags.id',
          :label_column => 'tags.name',
          :joins        => [ :taggings, :tags ],
          :capitalize   => true
        },

        {
          :title        => 'user',
          :query_option => 'member',
          :id_column    => 'users.id',
          :label_column => 'users.name',
          :joins        => [ :users ]
        },

        {
          :title        => 'licence',
          :query_option => 'license',
          :id_column    => 'licenses.id',
          :label_column => 'licenses.unique_name',
          :joins        => [ :licences ],
          :not_null     => true
        },

        {
          :title        => 'group',
          :query_option => 'network',
          :id_column    => 'networks.id',
          :label_column => 'networks.title',
          :joins        => [ :networks ]
        },

        {
          :title        => 'curation',
          :query_option => 'curation_event',
          :id_column    => 'curation_events.category',
          :label_column => 'curation_events.category',
          :joins        => [ :curation_events ],
          :capitalize   => true
        },
      ],

      :joins =>
      {
        :content_types   => "LEFT OUTER JOIN content_types ON contributions.content_type_id = content_types.id",
        :licences        => "LEFT OUTER JOIN licenses ON contributions.license_id = licenses.id",
        :users           => "INNER JOIN users ON contributions.contributor_type = 'User' AND contributions.contributor_id = users.id",
        :taggings        => "LEFT OUTER JOIN taggings ON contributions.contributable_type = taggings.taggable_type AND contributions.contributable_id = taggings.taggable_id",
        :tags            => "INNER JOIN tags ON taggings.tag_id = tags.id",
        :networks        => "INNER JOIN networks ON permissions.contributor_type = 'Network' AND permissions.contributor_id = networks.id",
        :credits         => "INNER JOIN creditations ON creditations.creditable_type = contributions.contributable_type AND creditations.creditable_id = contributions.contributable_id",
        :curation_events => "INNER JOIN curation_events ON curation_events.object_type = contributions.contributable_type AND curation_events.object_id = contributions.contributable_id"
      }
    }
  end

  def contributions_list(klass = nil, params = nil, user = nil, opts = {})

    def escape_sql(str)
      str.gsub(/\\/, '\&\&').gsub(/'/, "''")
    end

    def build_url(params, opts, parts, extra = {})

      query = {}

      if parts.include?(:filter)
        pivot_options[:filters].each do |filter|
          if params[filter[:query_option]]
            query[filter[:query_option]] = params[filter[:query_option]]
          end
        end
      end

      query["order"]        = params[:order]        if parts.include?(:order)
      query["filter_query"] = params[:filter_query] if parts.include?(:filter_query)
      query["advanced"]     = params[:advanced]     if parts.include?(:advanced)

      query.merge!(extra)

      if opts[:lock_filter]
        opts[:lock_filter].keys.each do |filter|
          query.delete(filter)
        end
      end

      query
    end

    def comparison(lhs, rhs)

      bits = rhs.split(",")

      if bits.length == 1
        "#{lhs} = '#{escape_sql(rhs)}'"
      else
        "#{lhs} IN ('#{bits.map do |bit| escape_sql(bit) end.join("', '")}')"
      end
    end

    def calculate_filter(params, filter, user, opts = {})

      # apply all the joins and conditions except for the current filter

      joins      = []
      conditions = []

      pivot_options[:filters].each do |other_filter|
        if filter_list = params[other_filter[:query_option]]
          unless opts[:inhibit_other_conditions]
            conditions << comparison(other_filter[:id_column], filter_list) unless other_filter == filter
          end
          joins += other_filter[:joins] if other_filter[:joins]
        end
      end

      joins += filter[:joins] if filter[:joins]
      conditions << "#{filter[:id_column]} IS NOT NULL" if filter[:not_null]

      unless opts[:inhibit_filter_query]
        if params[:filter_query]
          conditions << "(#{filter[:label_column]} LIKE '%#{escape_sql(params[:filter_query])}%')"
        end
      end

      current = params[filter[:query_option]] ? params[filter[:query_option]].split(',') : []

      if opts[:ids].nil?
        limit = 10
      else
        conditions << "(#{filter[:id_column]} IN ('#{opts[:ids].map do |id| escape_sql(id) end.join("','")}'))"
        limit = nil
      end

      objects = Authorization.authorised_index(Contribution,
          :all,
          :include_permissions => true,
          :select => "#{filter[:id_column]} AS filter_id, #{filter[:label_column]} AS filter_label, COUNT(DISTINCT contributions.contributable_type, contributions.contributable_id) AS filter_count",
          :joins => joins.length.zero? ? nil : joins.uniq.map do |j| pivot_options[:joins][j] end.join(" "),
          :conditions => conditions.length.zero? ? nil : conditions.join(" AND "),
          :group => filter[:id_column],
          :limit => limit,
          :order => "COUNT(DISTINCT contributions.contributable_type, contributions.contributable_id) DESC, #{filter[:label_column]}",
          :authorised_user => user).map do |object|

            value = object.filter_id.to_s
            selected = current.include?(value)

            if selected
              new_selection = (current - [value]).uniq.join(',')
            else
              new_selection = (current + [value]).uniq.join(',')
            end

            new_selection = nil if new_selection.empty?

            target_uri = build_url(params, opts, [:filter, :order, :filter_query, :advanced], filter[:query_option] => new_selection, "page" => nil)

            label = object.filter_label
            label = visible_name(label) if filter[:visible_name]
            label = label.capitalize    if filter[:capitalize]

            {
              :object   => object,
              :value    => value,
              :label    => label,
              :count    => object.filter_count,
              :uri      => target_uri,
              :selected => selected
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

      [ filters, cancel_filter_query_url ]
    end

    # apply locked filters

    if opts[:lock_filter]
      opts[:lock_filter].each do |filter, value|
        params[filter] = value
      end
    end

    # determine joins, conditions and order for the main results

    joins      = []
    conditions = []

    pivot_options[:filters].each do |filter|
      if filter_list = params[filter[:query_option]]
        conditions << comparison(filter[:id_column], filter_list)
        joins += filter[:joins] if filter[:joins]
      end
    end

    order_options = pivot_options[:order].find do |x|
      x[:option] == params[:order]
    end

    order_options ||= pivot_options[:order].first

    joins += order_options[:joins] if order_options[:joins]

    # perform the results query

    results = Authorization.authorised_index(klass,
        :all,
        :authorised_user => user,
        :include_permissions => true,
        :contribution_records => true,
        :page => { :size => params["num"] ? params["num"].to_i : nil, :current => params["page"] },
        :joins => joins.length.zero? ? nil : joins.uniq.map do |j| pivot_options[:joins][j] end.join(" "),
        :conditions => conditions.length.zero? ? nil : conditions.join(" AND "),
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

    filters, cancel_filter_query_url = calculate_filters(params, opts, user)

    # produce the summary.  If a filter query is specified, then we need to
    # recalculate the filters without the query to get all of them.

    if params[:filter_query]
      filters2 = calculate_filters(params, opts.merge( { :inhibit_filter_query => true } ), user)[0]
    else
      filters2 = filters
    end

    summary = ""

    filters2.select do |filter|

      next if opts[:lock_filter] && opts[:lock_filter][filter[:query_option]]

      selected = filter[:objects].select do |x| x[:selected] end

      if selected.length > 0
        if params[filter[:query_option]]

          selected_labels = selected.map do |x| x[:label] end

          if selected_labels.length > 1
            sentence = selected_labels[0..-2].join(", ") + " or " + selected_labels[-1]
          else
            sentence = selected_labels[0]
          end

          summary << '<span class="filter-in-use"><a href="' +
            url_for(build_url(params, opts, [:filter, :filter_query, :order, :advanced],
                  { filter[:query_option] => nil } )) +
            '"><b>' + filter[:title].capitalize + "</b>: " + sentence +
            " <img src='/images/famfamfam_silk/cross.png' /></a></span> "
        end
      end
    end

    if params[:filter_query]
      cancel_filter_query_url = build_url(params, opts, [:filter, :order, :advanced])
    end

    # remove filters that do not help in narrowing down the result set

    filters = filters.select do |filter|
      if filter[:objects].empty?
        false
#     elsif filter[:objects].length == 1 && filter[:objects][0][:selected] == false
#       false
      elsif params[:advanced].nil? && params[filter[:query_option]]
        false
      elsif params[:advanced].nil? && params[:filter_query].nil? && filter[:objects].length < 2
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
      :cancel_filter_query_url => cancel_filter_query_url,
      :filter_query_url        => build_url(params, opts, [:filter]),
      :summary                 => summary
    }
  end
end

