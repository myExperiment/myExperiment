# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def my_page?(user_id, user_type="User")
    logged_in? and current_user.id.to_i == user_id.to_i and current_user.class.to_s == user_type.to_s
  end

  def openid(user_id)
    begin
      User.find(user_id).openid_url
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def name(user_id)
    begin
      h(User.find(user_id).name)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def title(network_id)
    begin
      h(Network.find(network_id).title)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def avatar(user_id, size="200x200", link_to = true)
    begin
      user = User.find(user_id)
      
      if (user.profile.picture_id and !((img_id = user.profile.picture_id).to_i == 0))
        img = image_tag(url_for(:controller => 'pictures',
                                :action     => 'show',
                                :id         => img_id,
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
        link_to "[#{workflow.version}] - #{h(workflow.title)} (#{workflow.updated_at})", 
                :controller => 'workflows',
                :action => 'show',
                :id => workflow.id,
                :version => workflow.version
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
  
  def contributor(contributorid, contributortype, link=true)
    if contributortype.to_s == "User"
      return link ? profile_link(contributorid) : name(contributorid)
    elsif contributortype.to_s == "Network"
      return link ? link_to(title(contributorid), network_path(contributorid)) : title(contributorid)
    else
      return nil
    end
  end
end
