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
  def my_page?(user_id, user_type="User")
    logged_in? and current_user.id.to_i == user_id.to_i and current_user.class.to_s == user_type.to_s
  end
  
  def datetime(old_dt, long=true)
    return nil unless old_dt
    
    rtn = Time.at(old_dt)
    
    return long ? rtn.strftime("%A %d %B %Y @ %H:%M:%S (%Z)") : rtn.strftime("%d/%m/%y @ %H:%M:%S")
  end

  def openid(user_id, link_to=false)
    begin
      openid = User.find(user_id).openid_url
      
      return link_to ? link_to(openid, user_path(user_id)) : openid
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def name(user_id, link_to=false)
    begin
      name = h(User.find(user_id).name)
      
      return link_to ? link_to(name, user_path(user_id)) : name
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def title(network_id, link_to=false)
    begin
      title = h(Network.find(network_id).title)
      
      return link_to ? link_to(title, network_path(network_id)) : title
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def avatar(user_id, size="200x200", link_to=true)
    begin
      user = User.find(user_id)
      
      if user.profile.avatar?
        # need code for deciding whether to use small, medium or large!
        
        #img = image_tag(url_for_file_column(user.profile.picture, "data", "large"), 
        #                :title => h(user.name),
        #                :size => size)
        
        img = image_tag(url_for(:controller => 'pictures',
                                :action     => 'show',
                                :id         => user.profile.picture_id,
                                :size       => size),
                        :title => h(user.name))
          
        if link_to
          #return link_to img, profile_path(user.profile)
          return link_to(img, user_path(user))
        else
          return img
        end
      else
        img = image_tag("avatar.png", 
                        :title => h(user.name),
                        :size => size)
        
        if link_to
          #return link_to img, profile_path(user.profile)
          return link_to(img, user_path(user))
        else
          return img
        end
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def null_avatar(size="200x200")
    image_tag("avatar.png", :title => "Anonymous", :size => size)
  end
  
  def profile_link(user_id)
    begin
      user = User.find(user_id)
      
      #link_to h(user.name), profile_path(user.profile)
      return link_to(h(user.name), user_path(user))
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def messages_link(user_id)
    begin
      user = User.find(user_id)
      
      foo = "Inbox (#{user.messages_unread.length})"
      str = !user.messages_unread.empty? ? "<strong>" + foo + "</strong>" : foo
      
      link_to str, messages_path
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def memberships_pending_link(user_id)
    begin
      user = User.find(user_id)
      
      foo = "Memberships (#{user.memberships_pending.length})"
      str = !user.memberships_pending.empty? ? "<strong>" + foo + "</strong>" : foo
      
      link_to str, memberships_path(user.id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def friendships_pending_link(user_id)
    begin
      user = User.find(user_id)
      
      foo = "Friendships (#{user.friendships_pending.length})"
      str = !user.friendships_pending.empty? ? "<strong>" + foo + "</strong>" : foo
      
      link_to str, friendships_path(user.id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def request_membership_link(user_id, network_id)
    link_to "Request membership", url_for(:controller => 'memberships', 
                                          :action => 'new', 
                                          :user_id => user_id, 
                                          :network_id => network_id)
  end

  def request_friendship_link(user_id)
    link_to "Request friendship", new_friendship_url(:user_id => user_id)
  end
  
  def versioned_workflow_link(workflow_id, version_id)
    begin
      workflow = Workflow.find(workflow_id)
      
      if workflow.revert_to(version_id)
        url = url_for(:controller => 'workflows',
                      :action => 'show',
                      :id => workflow.id,
                      :version => workflow.version)
        
        "#{link_to "[#{workflow.version}]", url} - #{link_to "#{h(workflow.title)}", url} by #{contributor(workflow.contributor_id, workflow.contributor_type)} (#{datetime(workflow.updated_at, false)})"
      else
        nil
      end
    rescue ActiveRecord::RecordNotFound
      nil
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
  
  def contributor(contributorid, contributortype, link=true, avatar=false, size='100x100')
    if contributortype.to_s == "User"
      if avatar
        return render(:partial => "users/avatar", :locals => { :user => User.find(contributorid), :size => size })
      else
        return link ? profile_link(contributorid) : name(contributorid)
      end
    elsif contributortype.to_s == "Network"
      return link ? link_to(title(contributorid), network_path(contributorid)) : title(contributorid)
    else
      return nil
    end
  end
  
  def contributable(contributableid, contributabletype, link=true, thumb=false)
    case contributabletype.to_s
    when "Blob"
      if b = Blob.find(:first, :conditions => ["id = ?", contributableid])
        name = h(b.local_name)
        
        return link ? link_to(name, blob_path(b)) : name
      else
        return nil
      end
    when "Blog"
      if b = Blog.find(:first, :conditions => ["id = ?", contributableid])
        name = h(b.title)
        
        return link ? link_to(name, blog_path(b)) : name
      else
        return nil
      end
    when "Forum"
      if f = Forum.find(:first, :conditions => ["id = ?", contributableid])
        name = h(f.name)
        
        return link ? link_to(name, forum_path(f)) : name
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
        
        return link ? link_to(name, workflow_path(w)) : name
      else
        return nil
      end
    end
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
end
