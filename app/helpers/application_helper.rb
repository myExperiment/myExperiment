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
      img = null_avatar(size)
    end
    
    return link_to(img, user_url(user))
  end
  
  def null_avatar(size=200)
    image_tag "avatar.png", 
              :title => "Anonymous", 
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
  
  def versioned_workflow_link(workflow_id, version_id)
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
    
    return "#{link_to "[#{workflow.version}]", url} - #{link_to "#{h(workflow.title)}", url} by #{contributor(workflow.contributor_id, workflow.contributor_type)} (#{datetime(workflow.updated_at, false)})"
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
      return "Public (all)"
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
  
  def news(contributor, before=nil, after=nil, incl_assc=true)
    rtn = {}
    
    contributor_news(contributor, before, after, 0, incl_assc).each do |news_item|
      nearest_day = news_item[0] - (news_item[0].hour.hours + news_item[0].min.minutes + news_item[0].sec.seconds)
      
      if rtn.has_key? nearest_day
        rtn[nearest_day] << news_item[1]
      else
        rtn[nearest_day] = [news_item[1]]
      end
    end
    
    return rtn.sort { |a, b|
      b[0] <=> a[0]
    }
  end
  
protected
  
  def contributor_news(contributor, before, after, depth, incl_assc)
    rtn = []
    
    return rtn unless depth.to_i < 2
    
    if contributor.kind_of? User
      rtn = rtn + contributor_news!(contributor.memberships_accepted, before, after) # networks this user has joined
      rtn = rtn + contributor_news!(contributor.friendships_accepted, before, after) # friends this user has made
      rtn = rtn + contributor_news!(contributor.contributions, before, after) # contributions this user has made
      rtn = rtn + contributor_news!(contributor.networks_owned, before, after) # networks this user has created
      
      if incl_assc
        contributor.networks_owned.each do |network| # foreach network owned by the user
          rtn = rtn + contributor_news(network, before, after, depth.to_i+1, incl_assc)
        end
      
        contributor.friends.each do |friend| # foreach friend of the user
          rtn = rtn + contributor_news(friend, before, after, depth.to_i+1, incl_assc)
        end
      end
    elsif contributor.kind_of? Network
      rtn = rtn + contributor_news!(contributor.memberships_accepted, before, after) # memberships the network admin has accepted
      rtn = rtn + contributor_news!(contributor.contributions, before, after) # contributions this network has made
      
      #contributor.members(false).each do |member| # foreach member of the network
      #  rtn = rtn + contributor_news(member, before, after, depth.to_i+1, incl_assc)
      #end
    else
      return nil
    end
    
    #return rtn.sort { |a, b|
    #  b[0] <=> a[0]
    #}
    
    return rtn
  end
  
  def contributor_news!(collection, before, after)
    rtn = []
    
    collection.each do |item|
      case (item.class.to_s)
      when "Membership"
        next if before and item.accepted_at > before
        next if after and item.accepted_at < after
      
        rtn << [item.accepted_at, "#{name(item.user)} has joined the #{title(item.network)} network."]
      when "Friendship"
        next if before and item.accepted_at > before
        next if after and item.accepted_at < after
      
        rtn << [item.accepted_at, "#{name(item.user)} and #{name(item.friend)} have become friends."]
      when "Network"
        next if before and item.created_at > before
        next if after and item.created_at < after
      
        rtn << [item.created_at, "#{name(item.owner)} has created the #{title(item)} network."]
      when "Contribution"
        next if before and item.created_at > before
        next if after and item.created_at < after
      
        rtn << [item.created_at, "#{contributor(item.contributor_id, item.contributor_type)} has created the #{contributable(item.contributable_id, item.contributable_type)} #{item.contributable_type.downcase}."]
      else
        # do nothing!!
      end
    end
    
    return rtn
  end
end
