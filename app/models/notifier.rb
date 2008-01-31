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
  
  def membership_invite(user, network, base_url)
    recipients user.email
    from NOTIFICATIONS_EMAIL
    subject "myExperiment - you have been invited to join the #{network.title} Group"
    
    body :name => user.name,
         :username => user.username,
         :network => network,
         :base_url => base_url
  end
  
  def membership_request(requestor, network, base_url)
    recipients network.owner.email
    from NOTIFICATIONS_EMAIL
    subject "myExperiment - #{requestor.name} would like to join the #{network.title} Group"
    
    body :name => network.owner.name,
         :username => network.owner.username,
         :network => network,
         :base_url => base_url,
         :requestor_name => requestor.name
  end
  
  def auto_join_group(member, network, base_url)
    recipients network.owner.email
    from NOTIFICATIONS_EMAIL
    subject "myExperiment - #{member.name} has joined the #{network.title} Group"
    
    body :name => network.owner.name,
         :username => network.owner.username,
         :network => network,
         :base_url => base_url,
         :member_name => member.name
  end
  
  def new_message(message, base_url)
    recipients message.u_to.email
    from NOTIFICATIONS_EMAIL
    subject "myExperiment - #{message.u_from.name} has sent you a message"
    
    body :name => message.u_to.name,
         :username => message.u_to.username,
         :from_name => message.u_from.name,
         :base_url => base_url,
         :subject => message.subject
  end

end
