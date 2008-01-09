class Notifier < ActionMailer::Base
  
  NOTIFICATIONS_EMAIL = "notification@mail.myexperiment.com"

  def friendship_request(user, friend_name, base_url)
    recipients user.email
    from NOTIFICATIONS_EMAIL
    subject "myExperiment - #{friend_name} has requested to be your friend"
    
    body :name => user.name,
         :username => user.username,
         :friend_name => friend_name,
         :base_url => base_url
  end

end
