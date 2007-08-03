# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def openid(user_id)
    begin
      User.find(user_id).openid_url
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def avatar(user_id, size='200x200')
    begin
      user = User.find(user_id)
      
      if (img_id = user.profile.picture_id)
        link_to(image_tag(url_for(:controller => 'pictures',
                                  :action     => 'show',
                                  :id         => img_id,
                                  :size       => size),
                          :title => h(user.name)),
                profile_path(user.profile))
      else
        link_to(image_tag("avatar.png", 
                          :border => 1,
                          :title => h(user.name),
                          :size => size),
                profile_path(user.profile))
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
