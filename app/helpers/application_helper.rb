# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def current_user
    session[:user_id] ? User.find(session[:user_id]) : 0
  end
  
  def logged_in?
    current_user != 0
  end
  
  def my_page?(user_id)
    logged_in? and current_user.id.to_i == user_id.to_i
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
      User.find(user_id).name
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def title(network_id)
    begin
      Network.find(network_id).title
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
end
