# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def openid(user_id)
    begin
      User.find(user_id).openid_url
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
