# myExperiment: app/helpers/application_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'country_codes'
  
  def my_page?(contributor_id, contributor_type="User")
    #logged_in? and current_user.id.to_i == contributor_id.to_i and current_user.class.to_s == contributor_type.to_s

    return false unless logged_in?
    
    case contributor_type.to_s
    when "User"
      return current_user.id.to_i == contributor_id.to_i
    when "Network"
      return false unless Network.find(:first, :conditions => ["id = ? AND user_id = ?", contributor_id, current_user.id])
      return true
    else
      return false
    end
  end
  
  def mine?(thing)
    return false if thing.nil?
    return false unless logged_in?
    
    c_id = current_user.id.to_i
    
    case thing.class.to_s
    when "Workflow"
      return (c_id == thing.contribution.contributor_id.to_i and thing.contribution.contributor_type == "User")
    when "Blob"
      return (c_id == thing.contributor_id.to_i and thing.contributor_type == "User")
    when "Pack"
      return (c_id == thing.contributor_id.to_i and thing.contributor_type == "User")
    when "Network"
      return c_id == thing.user_id.to_i
    when "Friendship"
      return c_id == thing.friend_id
    when "Profile"
      return c_id == thing.user_id
    when "User"
      return c_id == thing.id 
    else
      return false
    end
  end
  
  def owner_text(thing)
    return '' if thing.nil?

    text = thing.class.owner_text if thing.class.respond_to?('owner_text')

    return '' if text.nil?

    text
  end
  
  def datetime(old_dt, long=true)
    return nil unless old_dt
    
    if old_dt.is_a?(DateTime)
      rtn = old_dt
    else
      rtn = Time.at(old_dt)
    end
    
    return long ? rtn.strftime("%A %d %B %Y @ %H:%M:%S (%Z)") : rtn.strftime("%d/%m/%y @ %H:%M:%S")
  end
  
  def date(old_dt, long=true)
    return nil unless old_dt
    
    rtn = Time.at(old_dt)
    
    return long ? rtn.strftime("%d %B %Y") : rtn.strftime("%d/%m/%y")
  end

  def openid(user_id)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id, openid_url", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    return link_to(user.openid_url, user.openid_url)
  end
  
  def name(user_id, truncate_to=nil)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id, name", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    name = truncate_to ? truncate(user.name, truncate_to) : name = user.name
    
    return link_to(h(name), user_url(user), :title => tooltip_title_attrib(h(user.name)))
  end
  
  def title(network_id, truncate_to=nil)
    if network_id.kind_of? Fixnum
      network = Network.find(:first, :select => "id, title", :conditions => ["id = ?", network_id]) 
      return nil unless network
    elsif network_id.kind_of? Network
      network = network_id
    else
      return nil
    end
    
    title = truncate_to ? truncate(network.title, truncate_to) : network.title
    return link_to(h(title), group_url(network))
  end
  
  def avatar(user_id, size=200, url=nil)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id, name", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    if user.avatar?
      img = image_tag avatar_url(user.profile.picture_id, size), :title => h(user.name), :class => 'framed'
    else
      img = null_avatar(size, h(user.name))
    end
    
    unless url
      url = user_url(user)
    end
    
    return link_to(img, url)
  end
  
  def avatar_url(picture_id, size=200)
    url_for(:controller => 'pictures',
            :action => 'show',
            :id => picture_id,
            :size => "#{size}x#{size}")
  end
  
  def null_avatar(size=200, alt="Anonymous")
    image_tag "avatar.png", 
              :title => alt, 
              :size => "#{size}x#{size}",
              :class => 'framed'
  end

  def signout_link
    icon('logout', session_path, nil, {:method => :delete}, "Logout")
  end
  
  def messages_link(user_id, text=nil)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id, openid_url", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    if !text
      text = "Inbox"  
    end
    
    unless (length = user.messages_unread.length) == 0
      text = "<b>" + text + " (#{length})</b>"
    end
    
    inbox = icon('message', messages_path, nil, nil, text)
    
    return inbox      
  end
  
  def memberships_link(user_id, text=nil)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    if !text
      text = "Memberships"  
    end
    
    unless (length = user.networks_membership_requests_pending.length + user.memberships_invited.length) == 0
      text = "<b>" + text + " (#{length})</b>"
    end
    
    mships = icon('membership', user_memberships_path(user), nil, nil, text)
    
    return mships
      
  end
  
  def friendships_pending_link(user_id)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    fships = icon('friendship', nil, nil, nil, nil) + " Friendships"
    
    unless (length = user.friendships_pending.length) == 0
       rtn = "<b>" + fships + " (#{length})</b>"
    else
      rtn = fships
    end
      
    return link_to(rtn, friendships_path(user))
  end
  
  def request_membership_link(user_id, network_id)
    icon('membership-new',
         url_for(:controller => 'memberships', :action => 'new', :user_id => user_id, :network_id => network_id),
         nil,
         nil,
         "Request Membership")
  end

  def request_friendship_link(user_id)
    link_to("Request Friendship", new_friendship_url(:user_id => user_id))
  end
  
  def versioned_workflow_link(workflow_id, version_number, long_description=true)
    if workflow_id.kind_of? Fixnum
      workflow = Workflow.find(:first, :conditions => ["id = ?", workflow_id])
      return nil unless workflow
    elsif workflow_id.kind_of? Workflow
      workflow = workflow_id
    else
      return nil
    end
    
    if (ver = workflow.find_version(version_number))
      url = url_for(:controller => 'workflows',
                    :action => 'show',
                    :id => workflow.id,
                    :version => version_number)
    else
      return nil
    end
    
    return nil unless url
    
    if long_description
      return "#{link_to "[#{ver.version}]", url} - #{link_to "#{h(ver.title)}", url}"
    else
      return link_to("#{h(ver.title)} [#{ver.version}]", url)
    end
  end
  
  def versioned_workflow_url(workflow_id, version_number)
    if workflow_id.kind_of? Fixnum
      workflow = Workflow.find(:first, :conditions => ["id = ?", workflow_id])
      return nil unless workflow
    elsif workflow_id.kind_of? Workflow
      workflow = workflow_id
    else
      return nil
    end
    
    if workflow.find_version(version_number)
      url = url_for(:controller => 'workflows',
                    :action => 'show',
                    :id => workflow.id,
                    :version => version_number)
    else
      return nil
    end
    
    return url
  end
  
  def filter_contributables(contributions, sort=false)
    rtn = {}
    
    contributions.each do |c|
      contributable = c.contributable
      
      if (arr = rtn[(klass = contributable.class.to_s)])
        arr << contributable
      else
        rtn[klass] = [contributable]
      end
    end
    
    # Sort alphabetically if required
    if sort
      rtn.each do |k, v|
        v.sort! { |a, b|
          at=a.title||""; bt=b.title||""; at.downcase <=> bt.downcase
        }
      end
    end
    
    return rtn
  end
  
  def aggregate_contributables(contributables)
    rtn = {}
    
    contributables.each do |t|
      if (arr = rtn[(klass = t.class.to_s)])
        arr << t
      else
        rtn[klass] = [t]
      end
    end
    
    return rtn
  end
  
  def contributor(contributorid, contributortype, avatar=false, size=100, you_text=false)
    if contributortype.to_s == "User"
      user = User.find(:first, :select => "id, name", :conditions => ["id = ?", contributorid])
      return nil unless user
      
      # this string will output " (you) " for current user next to the display name, when invoked with 'you_text == true'
      you_string = (you_text && logged_in? && user.id == current_user.id) ? "<small style='vertical-align: middle; color: #666666; margin-left: 0.5em;'>(you)</small>" : ""
      
      if avatar
        return render(:partial => "users/avatar", :locals => { :user => user, :size => size, :you_string => you_string })
      else
        return (name(user) + you_string)
      end
    elsif contributortype.to_s == "Network"
      network = Network.find(:first, :select => "id, title", :conditions => ["id = ?", contributorid])
      return nil unless network
      
      return title(network)
    else
      return nil
    end
  end
  
  def contributor_name(contributorid, contributortype)
    if contributortype.to_s == "User"
      user = User.find(:first, :select => "id, name", :conditions => ["id = ?", contributorid])
      return nil unless user
      
      return h(user.name)
    elsif contributortype.to_s == "Network"
      network = Network.find(:first, :select => "id, title", :conditions => ["id = ?", contributorid])
      return nil unless network
      
      return h(network.title)
    else
      return nil
    end
  end
  
  def contributable(contributableid, contributabletype, link=true, thumb=false)
    case contributabletype.to_s
    when "Blob"
      if b = Blob.find(:first, :conditions => ["id = ?", contributableid])
        if (b.title)
          if (b.title.length > 0)
            name = h(b.title)
          else 
            name = h(b.local_name)
          end
        else
          name = h(b.local_name)
        end
        
        return link ? link_to(name, file_url(b)) : name
      else
        return nil
      end
    when "Pack"
      if p = Pack.find(:first, :conditions => ["id = ?", contributableid])
        return link ? link_to(p.title, pack_url(p)) : h(p.title)
      else
        return nil
      end
    when "Blog"
      if b = Blog.find(:first, :conditions => ["id = ?", contributableid])
        name = h(b.title)
        
        return link ? link_to(name, blog_url(b)) : name
      else
        return nil
      end
    when "Workflow"
      if w = Workflow.find(:first, :conditions => ["id = ?", contributableid])
        name = h(w.title)
        
        if thumb
          unless w.image.nil?
            if Authorization.is_authorized?('show', nil, w, current_user)
              dot = image_tag url_for_file_column(w, "image", "thumb")
            else
              dot = image_tag url_for_file_column(w, "image", "padlock")
            end
            
            name = "#{dot}<br/>#{name}"
          end
        else
          dot = ""
        end
        
        return link ? link_to(name, workflow_url(w)) : name
      else
        return nil
      end
    end
  end
  
  def contributable_name(contributableid, contributabletype, truncate=nil)
    str = contributable(contributableid, contributabletype, false)
    
    return truncate ? truncate(str, truncate) : str
  end
  
  def contributable_url(contributableid, contributabletype, base_host=nil)
    if base_host.blank?
      return url_for(:controller => contributabletype.downcase.pluralize, 
                     :action => "show", 
                     :id => contributableid)
    else
      return url_for(:only_path => false,
                     :host => @base_url,
                     :controller => contributabletype.downcase.pluralize, 
                     :action => "show", 
                     :id => contributableid)
    end
  end
  
  def policy_link(policyid, managedby=true)
    if policyid.nil?
      return "Friends can view and download"
    elsif  p = Policy.find(:first, :conditions => ["id = ?", policyid])
      link = link_to(h(p.name), policy_path(p))
      
      if managedby
        return "#{link} (managed by: #{contributor(p.contributor_id, p.contributor_type)})"
      else
        return link
      end
    else
      return nil
    end
  end
  
  # http://www.igvita.com/blog/2006/09/10/faster-pagination-in-rails/
   def windowed_pagination_links(pagingEnum, options)
    link_to_current_page = options[:link_to_current_page]
    always_show_anchors = options[:always_show_anchors]
    padding = options[:window_size]

    current_page = pagingEnum.page
    html = ''

    #Calculate the window start and end pages 
    padding = padding < 0 ? 0 : padding
    first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
    last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page

    # Print start page if anchors are enabled
    html << yield(1) if always_show_anchors and not first == 1

    # Print window pages
    first.upto(last) do |page|
      (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
    end

    # Print end page if anchors are enabled
    html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
    html
  end
  
  def trim_body_html(body, limit=nil)
    truncate(body, limit)
    white_list(body)
  end
  
  def options_from_contributions_for_select(collection=[])
    hash = {}
    
    collection.each do |contribution|
      if hash.key? contribution.contributable_type
        hash[contribution.contributable_type] << contribution
      else 
        hash[contribution.contributable_type] = [contribution]
      end
    end
    
    html = ""
    
    hash.sort.each do |key_value_array|
      klass, arr = key_value_array[0], key_value_array[1]
      
      html = html + "<optgroup label=\"#{klass}\">"
      
      arr.each do |contribution|
        html = html + "<option value=\"#{contribution.id}\">#{contributable(contribution.contributable_id, contribution.contributable_type, false, false)}</option>"
      end
      
      html = html + "</optgroup>"
    end
    
    return html
  end
  
  def collection_contribution_tags(contributor, collection)
    contributor.collection_contribution_tags(collection)
  end
  
  def formatted_isbn(isbn)
    return nil if isbn.nil?
    
    if isbn.length.to_i == 10
      return "#{isbn[0..8]}-#{isbn[9..9]}"
    elsif isbn.length.to_i == 13
      return "#{isbn[0]}-#{isbn[1..6]}-#{isbn[7..12]}"
    else
      return nil
    end
  end
  
  def formatted_issn(issn)
    return nil if issn.nil?
    
    return "#{issn[0..3]}-#{issn[4..7]}"
  end
  
  def news(contributor, restrict_contributor=true, before=Time.now, after=Time.now-1.week, limit=30)
    hash = {}
    
    contributor_news(contributor, before, after, 0, (restrict_contributor ? contributor : nil)).sort! { |a, b|
      b[0] <=> a[0]
    }[0..limit].each do |news_item|
      nearest_day = news_item[0] - (news_item[0].hour.hours + news_item[0].min.minutes + news_item[0].sec.seconds)
      
      # bugfix to 'pad out' hours and minutes which are less than ten.. eg: 3:2 --> 03:02 [am]
      time = "#{(news_item[0].hour < 10 ? "0#{news_item[0].hour}" : news_item[0].hour)}:#{(news_item[0].min < 10 ? "0#{news_item[0].min}" : news_item[0].min)} -"
      
      if hash.has_key? nearest_day
        hash[nearest_day] << "#{time} #{news_item[1]}"
      else
        hash[nearest_day] = ["#{time} #{news_item[1]}"]
      end
    end
    
    rtn = hash.sort { |a, b|
      b[0] <=> a[0]
    }
    
    return rtn
  end
  
  def icon(method, url=nil, alt=nil, url_options={}, label=method.humanize, remote=false)

    if (label == 'Destroy')
      label = 'Delete';
    end

    return nil unless (filename = method_to_icon_filename(method.downcase))
    
    # if method.to_s == "info"
    # make into cool javascript div thing!
    
    image_options = alt ? { :alt => alt } : { :alt => method.humanize }
    img_tag = image_tag(filename, image_options)
    
    inner = img_tag;
    inner = "#{img_tag} #{label}" unless label == nil

    if (url)
      if (remote)
        inner = link_to_remote(inner, url, url_options);
      else
        inner = link_to(inner, url, url_options)
      end
    end

    return '<span class="icon">' + inner + '</span>';
  end
  
  
  # is exactly the same as icon, apart from that the front part of the url was already completely
  # generated before and is passed in as a parameter (this helps to get links with complex javascript in
  # 'onclick' field) - so need to add closing </a> tag in the relevant place
  def icon_no_link_processing(method, url=nil, alt=nil, label=method.humanize)

    if (label == 'Destroy')
      label = 'Delete';
    end

    return nil unless (filename = method_to_icon_filename(method.downcase))
    
    # if method.to_s == "info"
    # make into cool javascript div thing!
    
    image_options = alt ? { :alt => alt } : { :alt => method.humanize }
    img_tag = image_tag(filename, image_options)
    
    inner = img_tag;
    inner = "#{img_tag} #{label}" unless label == nil

    if (url)
      inner = url + inner + "</a>"
    end

    return '<span class="icon">' + inner + '</span>';
  end


  def method_to_icon_filename(method)
    case (method.to_s)
    when "refresh"
      return "famfamfam_silk/arrow_refresh.png"
    when "arrow_up"
      return "famfamfam_silk/arrow_up.png"
    when "arrow_down"
      return "famfamfam_silk/arrow_down.png"
    when "new"
      return "redmond_studio/add_16.png"
    when "download"
      return "redmond_studio/arrow-down_16.png"
      #return "manhattan_studio/save_24.png"
    when "show"
      return "famfamfam_silk/zoom.png"
      #return "redmond_studio/arrow-forward_24.png"
    when "edit"
      return "famfamfam_silk/pencil.png"
      #return "manhattan_studio/cut_24.png"
    when "manage"
      return "famfamfam_silk/wrench.png"
    when "destroy"
      return "famfamfam_silk/cross.png"
    when "tag"
      return "famfamfam_silk/tag_blue.png"
    when "favourite"
      return "famfamfam_silk/star.png"
    when "comment"
      return "famfamfam_silk/comment.png"
    when "comments"
      return "famfamfam_silk/comments.png"
    when "info"
      return "famfamfam_silk/information.png"
    when "help"
      return "famfamfam_silk/help.png"
    when "confirm"
      return "famfamfam_silk/accept.png"
    when "reject"
      return "famfamfam_silk/cancel.png"
    when "network"
      return "famfamfam_silk/group.png"
    when "network-member"
      return "famfamfam_silk/group.png"
    when "network-owned"
      return "famfamfam_silk/group_key.png"
    when "network-leave"
      return "famfamfam_silk/group_delete.png"
    when "network-invite"
      return "famfamfam_silk/group_add.png"
    when "user"
      return "famfamfam_silk/user.png"
    when "user-invite"
      return "famfamfam_silk/user_add.png"
    when "friend_delete"
      return "famfamfam_silk/user_delete.png"  
    when "avatar"
      return "famfamfam_silk/picture.png"
    when "save"
      return "famfamfam_silk/save.png"
    when "message"
      return "famfamfam_silk/email.png"
    when "message_read"
      return "famfamfam_silk/email_open.png"
    when "reply"
      return "famfamfam_silk/email_go.png"
    when "message_delete"
      return "famfamfam_silk/email_delete.png"  
    when "messages_outbox"
      return "famfamfam_silk/email_go.png"
    when "messages_outbox_no_arrow" # used only in 'show' page for a message, opened from outbox: this is for the icon for 'return to outbox' to differ from 'reply' icon
      return "famfamfam_silk/email.png"
    when "blob"
      return "redmond_studio/documents_16.png"
    when "pack"
      return "manhattan_studio/folder-closed_16.png"
    when "remote-resource"
      return "famfamfam_silk/page_world.png"
    when "blog"
      return "famfamfam_silk/note.png"
    when "workflow"
      return "redmond_studio/applications_16.png"
    when "policy"
      return "famfamfam_silk/key.png"
    when "logout"
      return "famfamfam_silk/door_out.png"
    when "login"
      return "famfamfam_silk/door_in.png"
    when "membership"
      return "famfamfam_silk/vcard.png"
    when "membership-new"
      return "famfamfam_silk/vcard_add.png"
    when "friendship"
      return "famfamfam_silk/user_comment.png"
    when "wizard"
      return "famfamfam_silk/wand.png"
    when "picture"
      return "famfamfam_silk/picture.png"
    when "pictures"
      return "famfamfam_silk/photos.png"
    when "profile"
      return "famfamfam_silk/user_suit.png"
    when "history"
      return "famfamfam_silk/time.png"   
    when "news"
      return "famfamfam_silk/newspaper.png"
    when "feedback"
      return "famfamfam_silk/user_comment.png"
    when "view-all"
      return "famfamfam_silk/table_go.png"
    when "announcement"
      return "famfamfam_silk/transmit.png"
    when "review"
      return "famfamfam_silk/report.png"
    when "experiment"
      return "famfamfam_silk/folder_wrench.png"
    when "job"
      return "famfamfam_silk/script_gear.png"
    when "runner"
      return "famfamfam_silk/server_key.png"
    when "xml"
      return "famfamfam_silk/page_code.png"
    when "package"
      return "famfamfam_silk/package.png"
    when "refresh"
      return "famfamfam_silk/arrow_refresh_small.png"
    when "rerun"
      return "famfamfam_silk/script_link.png"
    when "run-now"
      return "famfamfam_silk/script_add.png"
    when "timeline"
      return "famfamfam_silk/timeline_marker.png"
    when "remote"
      return "famfamfam_silk/world_link.png"
    when "denied"
      return "famfamfam_silk/exclamation.png"
    when "launch"
      return "famfamfam_silk/computer_go.png"
    when "register_application"
      return "famfamfam_silk/application_edit.png"
    else
      return Conf.label_icons[method.to_s] if Conf.label_icons[method.to_s]
    end
  end
  
  def refresh_image
    image_tag "refresh.gif", :style => "vertical-align: middle;"
  end
  
  def expand_image(margin_left="0.3em")
    image_tag "folds/unfold.png", :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => 'Expand'
  end
  
  def user_tags_for_thing(taggable, user_id)
    return [] if taggable.nil? or user_id.nil? 
    
    all_tags = taggable.taggings
    final_tags = []
    
    all_tags.each do |tagging|
      if tagging.user_id == user_id 
        final_tags += [tagging.tag]
      end
    end
    
    return final_tags
  end
  
  def tags_for_type(type, limit=-1)
    # Use a custom handcrafted sql query instead of the Tagging plugin functions (for perf reasons):
    sql="SELECT DISTINCT tags.* FROM tags INNER JOIN taggings ON tags.id=taggings.tag_id WHERE ( taggings.taggable_type = ? )  ORDER BY tags.taggings_count DESC"

    unless limit < 0
      sql+=" LIMIT #{limit}"
    end 

    tags=Tag.find_by_sql [ sql, type.capitalize ]

    return tags
  end

  def highlight_all(text, string)
    rtn = text
    
    string.each(separator=" ") { |substr|
      rtn = highlight(text, substr)
    }
    
    return rtn
  end
  
  
  def effective_policy(contribution)
    if contribution.policy == nil
      return Policy._default(contribution.contributor)
    else 
      return contribution.policy
    end
  end
  
  def all_workflows
    workflows = Workflow.find(:all, :order => "title ASC")
    workflows = workflows.select {|w| Authorization.is_authorized?('show', nil, w, current_user) }
  end
  
  def all_blobs
    blobs = Blob.find(:all)
    blobs.sort! { |x,y|
      x_title = (x.title and x.title.length > 0) ? x.title : x.local_name
      y_title = (y.title and y.title.length > 0) ? y.title : y.local_name
      x_title.downcase <=> y_title.downcase
    }
    blobs = blobs.select {|b| Authorization.is_authorized?('show', nil, b, current_user) }
  end
  
  def all_networks
    Network.find(:all, :order => "title ASC")
  end
  
  def all_nonfriends(user)
    users = User.find(:all) - user.friends - [ user ]
    users.sort! { |x,y|
      x.name.downcase <=> y.name.downcase
    } 
  end

  def all_users
    users = User.find(:all)
    users.sort! { |x,y|
      x.name.downcase <=> y.name.downcase
    }
  end
  
  def license_link(license_type)
    case license_type.downcase
    when "by-nd"
      return '<a rel="Copyright" href="http://creativecommons.org/licenses/by-nd/3.0/" target="_blank">Creative Commons Attribution-NoDerivs 3.0 License</a>'
    when "by"
      return '<a rel="Copyright" href="http://creativecommons.org/licenses/by/3.0/" target="_blank">Creative Commons Attribution 3.0 License</a>'
    when "by-sa"
      return '<a rel="Copyright" href="http://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-Share Alike 3.0 License</a>'
    end
  end
  
  def visible_name(entity)

    # Accept a string, the class object of a model or an instance of a model

    if (entity.instance_of?(String))
      name = entity
    elsif (entity.class == Class)
      name = entity.to_s
    else
      name = entity.class.to_s
    end

    # special case for a Session object, though I'm not convinced that it's
    # still used anywhere (Don)

    exit if name == "Session"

    # substitute model alias in singular form

    if Conf.model_aliases.value?(name)
      Conf.model_aliases.each do |al, model|
        name = al if name == model
      end
    end
        
    name
  end
  
  def controller_visible_name(humanized_controller_for)

    # special case for Session, though I don't think it's needed any more (Don)

    return "Log in" if humanized_controller_for == "Session"

    # substitute model alias in plural form

    Conf.model_aliases.each do |al, model|
      humanized_controller_for = al.pluralize if humanized_controller_for == model.pluralize
    end

    humanized_controller_for
  end

  def sharing_mode_text(contributable, mode)

    c_type = visible_name(contributable)

    case mode
    when 0
      return 'Anyone can view and download.'
    when 1
      return 'Anyone can view, but only Friends are allowed to download.'
    when 2
      return 'Anyone can view, but only the uploader can download.'
    when 3
      return 'Only Friends can view and download.'
    when 4
      return 'Only Friends can view, but only the uploader can download.'
    when 5, 6, 7
      return "This is a private #{c_type} - only the uploader can view and download (and any Groups explicitly shared with)."
    when 8
      return "This #{c_type} has custom sharing permissions."
    end
  end
  
  def updating_mode_text(contributable, mode)

    c_type = visible_name(contributable)

    case mode
    when 0
      return "All those that can view and download can also update."
    when 1
      return "All the uploader's Friends can update."
    when 5
      return "A specific set of Users can update."
    when 2, 3, 4, 6
      return "Only the uploader may update this #{c_type} (and any Groups explicitly given update permissions)."
    when 7
      return "This #{c_type} has custom updating permissions."
    end
  end
  
  def c_resource_string(contributable)
    
    c_type = visible_name(contributable)
    
    case c_type
    when "File"
      return 'file';
    when "Workflow"
      return 'Workflow file'
    else
      return c_type
    end
  end
  
  def friend_badge(user)
    if user and logged_in? and user.id != current_user.id
      return image_tag("friend_badge.png", :class => 'badge') if (user.friend? current_user.id)
    else 
      return ''
    end
  end
  
  def admin_badge(user)
    if user.admin?
      return image_tag("admin_badge.png", :class => 'badge')
    else 
      return ''
    end
  end
  
  def help_icon_with_tooltip(info_text, delay=200)
    return image_tag("famfamfam_silk/help.png",
              :title => tooltip_title_attrib(info_text, delay),
              :style => "vertical-align:middle;")
  end
  
  def info_icon_with_tooltip(info_text, delay=200)
    return image_tag("famfamfam_silk/information.png",
              :title => tooltip_title_attrib(info_text, delay),
              :style => "vertical-align:middle;")
  end
  
  def tooltip_title_attrib(text, delay=200)
    return "header=[] body=[#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[#{delay}]"
  end
  
  # This method checks to see if the current user is allowed to approve a membership that is still pending approval
  def allow_membership_pending_approval(membership)
    if logged_in?
      if membership.user_established_at == nil
        return membership.user_id == current_user.id
      elsif membership.network_established_at == nil
        return current_user.id == membership.network.owner.id
      end 
    else
      return false
    end
  end
  
  def allowed_html_text(align='left')
    return "<p style=\"font-size: 85%; color: #333333; text-align:#{align}\">Note: some HTML is allowed: &lt;p&gt;, &lt;a&gt;, &lt;b&gt;, &lt;blockquote&gt;, &lt;em&gt;, &lt;i&gt;, &lt;strong&gt; and &lt;u&gt;.</p>"    
  end
  
  def flag_icon(country, text=country, margin_right='0.3em')
    return '' if country.nil? or country.empty?
    
    code = ''
    
    if country.downcase == "great britain"
      code = "gb"
    elsif ["england", "wales", "scotland"].include?(country.downcase)
      code = country
    elsif country.length > 2
      code = CountryCodes.code(country)
    else
      code = country if CountryCodes.valid_code?(country)
    end
    
    #puts "code = " + code
    
    unless code.nil? or code.empty?
      return image_tag("famfamfam_flags/#{code.downcase}.png",
              :title => "header=[] body=[<b>Location: </b>#{text}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[200]",
              :style => "vertical-align:middle; margin-right: #{margin_right};")
    else
      return ''
    end
  end
  
  def workflow_version_edit_url(workflow_id, version_number)
    return url_for(:controller => "workflows",
                   :id => workflow_id,
                   :action => "edit_version",
                   :version => version_number)
  end
  
  def workflow_version_delete_url(workflow_id, version_number)
    return url_for(:controller => "workflows",
                   :id => workflow_id,
                   :action => "destroy_version",
                   :version => version_number)
  end
  
  def thing_authorized?(action, thing)
    # method preserved only in case some code absolutely requires it in the future;
    # for now (Jan 2009) all occurrences of it's usage were replaced with Authorization.is_authorized?()
    return Authorization.is_authorized?(action, nil, thing, current_user)
  end
  
  def strip_html(str, preserve_tags=[])
    str = str.strip || ''
    preserve_arr = preserve_tags.join('|') << '|\/'
    str.gsub(/<(\/|\s)*[^(#{preserve_arr})][^>]*>/,'')
  end
  
  def feed_icon_tag(title, url, style='')
    (@feed_icons ||= []) << { :url => url, :title => title }
    alt_text = "Subscribe to #{title} feed"
    link_to image_tag('feed-icon.png', :alt => alt_text, :title => tooltip_title_attrib(alt_text), :style => "vertical-align: middle; padding: 0;" + style), url
  end
  
  def download_icon_tag(title, url, style='')
    filename = method_to_icon_filename("download")
    link_to image_tag(filename, :alt => "Download", :title => tooltip_title_attrib(title), :style => "vertical-align: middle; padding: 0;" + style), url
  end
  
  # NOTE: the timeago methods below are used instead of the built in Rails DateHelper methods
  # because they don't seem to be working.

  # From: http://actsasflinn.com/articles/2007/04/10/time-ago-method-for-ruby-on-rails
  # options
  # :start_date, sets the time to measure against, defaults to now
  # :later, changes the adjective and measures time forward
  # :round, sets the unit of measure 1 = seconds, 2 = minutes, 3 hours, 4 days, 5 weeks, 6 months, 7 years (yuck!)
  # :max_seconds, sets the maximimum practical number of seconds before just referring to the actual time
  # :date_format, used with <tt>to_formatted_s<tt>
  def timeago(original, options = {})
    start_date = options.delete(:start_date) || Time.now
    later = options.delete(:later) || false
    round = options.delete(:round) || 7
    max_seconds = options.delete(:max_seconds) || 32556926
    date_format = options.delete(:date_format) || :default
  
    # array of time period chunks
    chunks = [
      [60 * 60 * 24 * 365 , "year"],
      [60 * 60 * 24 * 30 , "month"],
      [60 * 60 * 24 * 7, "week"],
      [60 * 60 * 24 , "day"],
      [60 * 60 , "hour"],
      [60 , "minute"],
      [1 , "second"]
    ]
  
    if later
      since = original.to_i - start_date.to_i
    else
      since = start_date.to_i - original.to_i
    end
    time = []
  
    if since < max_seconds
      # Loop trough all the chunks
      totaltime = 0
  
      for chunk in chunks[0..round]
        seconds    = chunk[0]
        name       = chunk[1]
  
        count = ((since - totaltime) / seconds).floor
        time << pluralize(count, name) unless count == 0
  
        totaltime += count * seconds
      end
  
      if time.empty?
        "less than a #{chunks[round-1][1]} ago"
      else
        "#{time.join(', ')} #{later ? 'later' : 'ago'}"
      end
    else
      original.to_formatted_s(date_format)
    end
  end
  
  # Based on: http://actsasflinn.com/articles/2007/04/10/time-ago-method-for-ruby-on-rails
  # options
  # :start_date, sets the time to measure against, defaults to now
  # :date_format, used with <tt>to_formatted_s<tt>, default to :default
  def timeago_fuzzy(time, options = {})
    start_date = options.delete(:start_date) || Time.new
    date_format = options.delete(:date_format) || :default
    delta_minutes = (start_date.to_i - time.to_i).floor / 60
    if delta_minutes.abs <= (8760*60) # 365 days
      distance = time_distance_in_words(delta_minutes);
      if delta_minutes < 0
        "#{distance} from now"
      else
        "#{distance} ago"
      end
    else
      return "more than 1 year ago"
    end
  end

  def time_distance_in_words(minutes)
    case
      when minutes < 1
        "less than a minute"
      when minutes < 50
        pluralize(minutes, "minute")
      when minutes < 90
        "about one hour"
      when minutes < 1080
        "#{(minutes / 60).round} hours"
      when minutes < 1440
        "one day"
      when minutes < 2880
        "about one day"
      else
        "#{(minutes / 1440).round} days"
    end
  end
  
  def home_url
    return url_for(:controller => 'home')
  end
  
  def find_permission_for_contributor(perms, contributor_type, contributor_id)
    perm = nil;
    filtered = perms.select { |p| (p.contributor_id == contributor_id and p.contributor_type == contributor_type) }
    if filtered.length > 0
      perm = filtered[0]
    end
    perm
  end
  
  def currentusers_things_url(thing)
    return nil unless current_user
    return url_for(:controller => 'users',
                   :id => current_user.id,
                   :action => thing)
  end
  
  def view_privileges_notice
    content_tag(:p, 
                view_privileges_text,
                :class => "box_currentuser_specific",
                :style => "font-size: 93%; font-weight: bold; color: #333333; padding: 0.3em 0.5em;")
  end
  
  def view_privileges_text
    return "Note: some items may not be visible to you, due to viewing permissions."
  end
  
  def downloadable?(type)
    if ['workflow', 'blob', 'pack'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def reviewable?(type)
    if ['workflow'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def commentable?(type)
    if ['workflow', 'network', 'blob', 'pack'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def taggable?(type)
    if ['workflow', 'network', 'blob', 'pack'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def rateable?(type)
    if ['workflow', 'blob'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def favouritable?(type)
    if ['workflow', 'blob', 'pack'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def allow_credits_and_attributions?(type)
    if ['workflow', 'blob'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def allow_citations?(type)
    if ['workflow'].include? type.downcase
      return true
    else
      return false
    end
  end
  
  def delete_image(style=nil, tooltip="Delete")
    return image_tag("famfamfam_silk/cross.png",
              :title => "header=[] body=[#{tooltip}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[200]",
              :style => style)
  end
  
  def edit_image(style=nil, tooltip="Edit") 
    return image_tag("famfamfam_silk/pencil.png",
              :title => "header=[] body=[#{tooltip}] cssheader=[boxoverTooltipHeader] cssbody=[boxoverTooltipBody] delay=[200]",
              :style => style)
  end
  
  def new_flash_image(style=nil)
   return image_tag("famfamfam_silk/new.png", 
                    :style => style)
  end
  
  def update_perms_info_text(contributable)
    return nil if contributable.nil?
    
    resource = c_resource_string(contributable)
    visible_type = visible_name(contributable)
    
    text = "<p>By giving update permission for this #{visible_type}, you allow other users to do the following:</p>"
    
    case contributable.class.to_s
      when 'Workflow'
        text += "<ul>
                  <li>Upload new versions of the #{visible_type} as part of this #{visible_type} entry.</li> 
                  <li>Edit the titles and descriptions of the different #{visible_type} versions.</li>
                </ul>"
      when 'Blob'
        text+= "<ul>
                  <li>NO additional update priviledges are available for #{visible_type.pluralize}.</li>
                </ul>" 
      when 'Pack'
        text += "<ul>
                  <li>Add new items to the #{visible_type}.</li>
                  <li>Edit metadata of existing items.</li>
                </ul>"
      else
        text += "<ul><li>ERROR: the contributable type does not have any update permissions info text set for it.</li></ul>"
    end
    
    text += "<p>
              Note that updating privileges only affect how other users can update this
              #{visible_type} entry on #{Conf.sitename}. If the user downloads the #{resource},
              they can still edit it away from #{Conf.sitename} and possible upload it back as a new entry.
            </p>"
            
    return text
  end
  
  # From: http://ajax.howtosetup.info/ruby/finding-mean-median-and-mode-2/
  def mean(array)
    if array.length == 0 
      return 0
    else
      return array.inject(0) { |sum, x| sum += x } / array.size.to_f  
    end
  end

  
protected

  def contributor_news(contributor, before, after, depth, restrict_contributor)
    rtn = []
    
    return rtn unless depth.to_i < 2
    
    collections = [[contributor], contributor.contributions, contributor.workflows, contributor.blogs]
    recursions = []
    
    case contributor.class.to_s
    when "User"
      collections = collections + [contributor.memberships_accepted, contributor.friendships_accepted, contributor.networks_owned, contributor.picture_selections]
      recursions = recursions + [contributor.networks, contributor.networks_owned, contributor.friends]
    when "Network"
      collections = collections + [contributor.memberships_accepted]
      recursions = recursions + [contributor.members]
    else
      # do nothing!
    end
    
    collections.each do |collection|
      collection.each do |item|
        rtn = rtn + contributor_news!(item, before, after, restrict_contributor)
      end
    end
    
    recursions.each do |collection|
      collection.each do |c|
        rtn = rtn + contributor_news(c, before, after, depth.to_i+1, restrict_contributor)
      end
    end
    
    return rtn.uniq # remove duplicate items due to recursion
  end
  
  def contributor_news!(item, before, after, restrict_contributor)
    rtn = []
    
    case (item.class.to_s)
    when "Membership"
      return rtn if before and item.accepted_at > before
      return rtn if after and item.accepted_at < after
        
      if restrict_contributor
        case restrict_contributor.class.to_s
        when "User"
          return rtn unless item.user.id.to_i == restrict_contributor.id.to_i
        when "Network"
          return rtn unless item.network.id.to_i == restrict_contributor.id.to_i
        else
          return rtn
        end
      end
      
      rtn << [item.accepted_at, "#{name(item.user)} joined the #{title(item.network)} Group."]
    when "Friendship"
      return rtn if before and item.accepted_at > before
      return rtn if after and item.accepted_at < after
        
      if restrict_contributor 
        return rtn unless (restrict_contributor.class.to_s == "User" and [item.user.id.to_i, item.friend.id.to_i].include? restrict_contributor.id.to_i)
      end
      
      rtn << [item.accepted_at, "#{name(item.user)} and #{name(item.friend)} became friends."]
    when "Network"
      return rtn if before and item.created_at > before
      return rtn if after and item.created_at < after
        
      if restrict_contributor
        case restrict_contributor.class.to_s
        when "User"
          return rtn unless item.owner.id.to_i == restrict_contributor.id.to_i
        when "Network"
          return rtn unless item.id.to_i == restrict_contributor.id.to_i
        else
          return rtn
        end
      end
      
      rtn << [item.created_at, "#{name(item.owner)} created the #{title(item)} Group."]
    when "User"
      return rtn if before and item.created_at > before
      return rtn if after and item.created_at < after
        
      if restrict_contributor
        return rtn unless (restrict_contributor.class.to_s == "User" and item.id.to_i == restrict_contributor.id.to_i)
      end
      
      rtn << [item.created_at, "#{name(item)} joined #{link_to Conf.sitename, "/"}."]
    when "Contribution"
      return rtn if before and item.created_at > before
      return rtn if after and item.created_at < after
        
      owner = contributor(item.contributor_id, item.contributor_type)
      editor = contributor(item.contributable.contributor_id, item.contributable.contributor_type)
        
      if restrict_contributor 
        return rtn unless ([item.contributable.contributor_type, item.contributor_type].include? restrict_contributor.class.to_s and [item.contributable.contributor_id, item.contributor_id].include? restrict_contributor.id.to_i)
      end
      
      case item.contributable_type.to_s
      when "Workflow"
        if item.contributable.current_version.to_i == 1
          title = item.contributable.title
        else
          title = item.contributable.versions[0].title
        end
          
        link = link_to h(title), url_for(:controller => :workflows, :action => :show, :id => item.contributable_id, :version => 1)
      else
        link = contributable(item.contributable_id, item.contributable_type)
      end
        
      if owner.to_s == editor.to_s
        rtn << [item.created_at, "#{owner} created the #{link} #{item.contributable_type.downcase == "blob" ? "File" : item.contributable_type.downcase}."]
      else
        case item.contributor_type
        when "Network"
          owner_string = "the #{owner} network"
        else
          owner_string = owner
        end
        
        rtn << [item.created_at, "#{editor} created the #{link} #{item.contributable_type.downcase == "blob" ? "File" : item.contributable_type.downcase} for #{owner_string}."]
      end
    when "Blog"
      if restrict_contributor
        return rtn unless (restrict_contributor.class.to_s == item.contributor_type.to_s and restrict_contributor.id.to_i == item.contributor_id.to_i)
      end
      
      owner = contributor(item.contributor_id, item.contributor_type)
    
      item.posts.each do |blog_post|
        next if before and blog_post.created_at > before
        next if after and blog_post.created_at < after
        
        rtn << [blog_post.created_at, "#{owner} has created a new post on #{contributable(item.id, "Blog")}."]
      end
    when "Workflow"
      item.versions.each do |workflow|
        next if workflow.version.to_i == 1
        next if before and workflow.updated_at > before
        next if after and workflow.updated_at < after
        
        editor = contributor(workflow.contributor_id, workflow.contributor_type)
        
        if restrict_contributor
          next unless (workflow.contributor_type.to_s == restrict_contributor.class.to_s and workflow.contributor_id.to_i == restrict_contributor.id.to_i)
        end
        
        rtn << [workflow.updated_at, "#{editor} edited the #{versioned_workflow_link(item.id, workflow.version, false)} Workflow."]
      end
    when "PictureSelection"
      return rtn if before and item.created_at > before
      return rtn if after and item.created_at < after
        
      if restrict_contributor
        return rtn unless (restrict_contributor.class.to_s == "User" and item.user_id.to_i == restrict_contributor.id.to_i)
      end
      
      rtn << [item.created_at, "#{name(item.user)} selected a new avatar #{link_to image_tag(avatar_url(item.picture_id, 50)), user_path(item.user)}."]
    else
      return rtn
    end
    
    return rtn
  end

  def permissions_categorised(permissions)
    permissions_categorised={'announcement'=>[],'citation'=>[],'comment'=>[],'download'=>[],'experiment'=>[],'file'=>[],'group'=>[],'job'=>[],'message'=>[],'pack'=>[],'picture'=>[],'review'=>[],'runner'=>[],'tag'=>[],'user'=>[],'workflow'=>[],'miscellaneous'=>[]};
    categories=permissions_categorised.keys
    for key,permission in permissions
      category_found=false
      for category in categories
        if key.include?(category)
          permissions_categorised[category].push(permission)
          category_found=true
        end
      end
      unless category_found
        permissions_categorised['miscellaneous'].push(permission)
      end
    end
    permissions_categorised=permissions_categorised.sort
    return permissions_categorised
  end

  def permissions_show_categorised(permissions)
    permissions_categorised={'announcement'=>[],'citation'=>[],'comment'=>[],'download'=>[],'experiment'=>[],'file'=>[],'group'=>[],'job'=>[],'message'=>[],'pack'=>[],'picture'=>[],'review'=>[],'runner'=>[],'tag'=>[],'user'=>[],'workflow'=>[],'miscellaneous'=>[]};
    categories=permissions_categorised.keys
    for permission in permissions
      category_found=false
      for category in categories
        if permission.for.include?(category)
          permissions_categorised[category].push(permission.for)
          category_found=true
        end
      end
      unless category_found
        permissions_categorised['miscellaneous'].push(permission.for)
      end
    end
    permissions_categorised=permissions_categorised.sort
    return permissions_categorised
  end

  def indefinite_article(text)
    text.match(/^[aeiou]/i) ? "an" : "a"
  end
 
  def comma_list(strings)

    return ""         if strings.empty?
    return strings[0] if strings.length == 1

    strings[0..-2].join(", ") + " and " + strings[-1]
  end

end
