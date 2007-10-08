##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
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
  
  def datetime(old_dt, long=true)
    return nil unless old_dt
    
    rtn = Time.at(old_dt)
    
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
    
    name = truncate_to ? truncate(user.name, truncate_to) : user.name
    return link_to(h(name), user_url(user))
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
    return link_to(h(title), network_url(network))
  end
  
  def avatar(user_id, size=200)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id, name", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    if user.avatar?
      img = image_tag url_for(:controller => 'pictures',
                              :action => 'show',
                              :id => user.profile.picture_id,
                              :size => "#{size}x#{size}"),
                      :title => h(user.name)
    else
      img = null_avatar(size, h(user.name))
    end
    
    return link_to(img, user_url(user))
  end
  
  def null_avatar(size=200, alt="Anonymous")
    image_tag "avatar.png", 
              :title => alt, 
              :size => "#{size}x#{size}"
  end
  
  def messages_link(user_id)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id, openid_url", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    inbox = "Inbox (#{user.messages_unread.length})"
    rtn = !user.messages_unread.empty? ? "<strong>" + inbox + "</strong>" : inbox
      
    return link_to(rtn, messages_path)
  end
  
  def memberships_pending_link(user_id)
    if user_id.kind_of? Fixnum
      user = User.find(:first, :select => "id", :conditions => ["id = ?", user_id]) 
      return nil unless user
    elsif user_id.kind_of? User
      user = user_id
    else
      return nil
    end
    
    mships = "Memberships (#{user.memberships_pending.length})"
    rtn = !user.memberships_pending.empty? ? "<strong>" + mships + "</strong>" : mships
      
    return link_to(rtn, memberships_path(user))
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
    
    fships = "Friendships (#{user.friendships_pending.length})"
    rtn = !user.friendships_pending.empty? ? "<strong>" + fships + "</strong>" : fships
      
    return link_to(rtn, friendships_path(user))
  end
  
  def request_membership_link(user_id, network_id)
    link_to("Request membership", url_for(:controller => 'memberships', 
                                          :action => 'new', 
                                          :user_id => user_id, 
                                          :network_id => network_id))
  end

  def request_friendship_link(user_id)
    link_to("Request friendship", new_friendship_url(:user_id => user_id))
  end
  
  def versioned_workflow_link(workflow_id, version_id, long_description=true)
    if workflow_id.kind_of? Fixnum
      workflow = Workflow.find(:first, :conditions => ["id = ?", workflow_id])
      return nil unless workflow
    elsif workflow_id.kind_of? Workflow
      workflow = workflow_id
    else
      return nil
    end
    
    if workflow.revert_to(version_id)
      url = url_for(:controller => 'workflows',
                    :action => 'show',
                    :id => workflow.id,
                    :version => workflow.version)
    else
      return nil
    end
    
    if long_description
      return "#{link_to "[#{workflow.version}]", url} - #{link_to "#{h(workflow.title)}", url} by #{contributor(workflow.contributor_id, workflow.contributor_type)} (#{datetime(workflow.updated_at, false)})"
    else
      return link_to("#{h(workflow.title)} [#{workflow.version}]", url)
    end
  end
  
  def filter_contributables(contributions)
    rtn = {}
    
    contributions.each do |c|
      contributable = c.contributable
      
      if (arr = rtn[(klass = contributable.class.to_s)])
        arr << contributable
      else
        rtn[klass] = [contributable]
      end
    end
    
    return rtn
  end
  
  def contributor(contributorid, contributortype, avatar=false, size=100)
    if contributortype.to_s == "User"
      user = User.find(:first, :select => "id, name", :conditions => ["id = ?", contributorid])
      return nil unless user
      
      return name(user) unless avatar
      return avatar(user, size) + "<br/>" + name(user)
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
        name = h(b.local_name)
        
        return link ? link_to(name, blob_url(b)) : name
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
    when "Forum"
      if f = Forum.find(:first, :conditions => ["id = ?", contributableid])
        name = h(f.name)
        
        return link ? link_to(name, forum_url(f)) : name
      else
        return nil
      end
    when "Workflow"
      if w = Workflow.find(:first, :conditions => ["id = ?", contributableid])
        name = h(w.title)
        
        if thumb
          unless w.image.nil?
            if w.authorized?("show", (logged_in? ? current_user : nil))
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
  
  def contributable_url(contributableid, contributabletype)
    return url_for(:controller => contributabletype.downcase.pluralize, :action => "show", :id => contributableid)
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
  
  def trim_body_html(body, limit=nil, truncate_string="...")
    body = "#{body[0..limit]}.." if limit and body.length > limit
    
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
  
  def news(contributor, restrict_contributor, before=Time.now, after=Time.now-1.week, limit=30)
    hash = {}
    
    contributor_news(contributor, before, after, 0, (restrict_contributor ? nil : contributor)).sort! { |a, b|
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
  
  def icon(method, url=nil, alt=nil, url_options={}, label=method.humanize)

    if (label == 'Destroy')
      label = 'Remove';
    end

    return nil unless (filename = method_to_icon_filename(method.downcase))
    
    # if method.to_s == "info"
    # make into cool javascript div thing!
    
    image_options = alt ? { :alt => alt } : { :alt => method.humanize }
    img_tag = image_tag(filename, image_options)
    
    inner = img_tag;
    inner = "#{img_tag} #{label}" unless label == nil

    return '<span class="icon">' +
      (url ? link_to(inner, url, url_options) : inner) + '</span>';
  end

  def method_to_icon_filename(method)
    case (method.to_s)
    when "new"
      return "manhattan_studio/add_16.png"
    when "download"
      return "manhattan_studio/arrow-down_16.png"
      #return "manhattan_studio/save_24.png"
    when "show"
      return "manhattan_studio/arrow-forward_16.png"
      #return "redmond_studio/arrow-forward_24.png"
    when "edit"
      return "famfamfam_silk/pencil.png"
      #return "manhattan_studio/cut_24.png"
    when "destroy"
      return "manhattan_studio/delete_16.png"
      #return "manhattan_studio/delete_24.png"
    when "tag"
      return "famfamfam_silk/tag_blue.png"
    when "bookmark"
      return "famfamfam_silk/book_open.png"
    when "comment"
      return "famfamfam_silk/comment.png"
    when "info"
      return "famfamfam_silk/information.png"
    when "confirm"
      return "famfamfam_silk/accept.png"
    when "reject"
      return "famfamfam_silk/cancel.png"
    when "network-member"
      return "famfamfam_silk/world.png"
    when "user"
      return "famfamfam_silk/user.png"
    when "save"
      return "famfamfam_silk/save.png"
    when "help"
      return "famfamfam_silk/help.png"
    else
      return nil
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
      collections = collections + [contributor.memberships_accepted, contributor.friendships_accepted, contributor.networks_owned]
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
      
      rtn << [item.accepted_at, "#{name(item.user)} joined the #{title(item.network)} network."]
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
      
      rtn << [item.created_at, "#{name(item.owner)} created the #{title(item)} network."]
    when "User"
      return rtn if before and item.created_at > before
      return rtn if after and item.created_at < after
        
      if restrict_contributor
        return rtn unless (restrict_contributor.class.to_s == "User" and item.id.to_i == restrict_contributor.id.to_i)
      end
      
      rtn << [item.created_at, "#{name(item)} joined #{link_to "myExperiment", "/"}."]
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
        if item.contributable.version.to_i == 1
          title = item.contributable.title
        else
          title = item.contributable.versions[0].title
        end
          
        link = link_to h(title), url_for(:controller => :workflows, :action => :show, :id => item.contributable_id, :version => 1)
      else
        link = contributable(item.contributable_id, item.contributable_type)
      end
        
      if owner.to_s == editor.to_s
        rtn << [item.created_at, "#{owner} created the #{link} #{item.contributable_type.downcase}."]
      else
        case item.contributor_type
        when "Network"
          owner_string = "the #{owner} network"
        else
          owner_string = owner
        end
        
        rtn << [item.created_at, "#{editor} created the #{link} #{item.contributable_type.to_s == "Blob" ? "file" : item.contributable_type.downcase} for #{owner_string}."]
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
        
        rtn << [workflow.updated_at, "#{editor} edited the #{versioned_workflow_link(item.id, workflow.version, false)} workflow."]
      end
    else
      return rtn
    end
    
    return rtn
  end
  
  def gadget_characters_limit
	return 20
  end
  
end
