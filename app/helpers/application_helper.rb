# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def openid(user_id)
    begin
      User.find(user_id).openid_url
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
  
  def avatar(user_id)
    begin
      profile = User.find(user_id).profile
    
      link_to image_tag(url_for(:controller => 'pictures',
                                :action     => 'show',
                                :id         => profile.picture_id,
                                :size       => '200x200')),
              profile_path(profile)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
