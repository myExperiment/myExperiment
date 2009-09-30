class Notifier < ActionMailer::Base

  helper :application

  def friendship_request(user, friend_name, friendship, base_url)
    recipients user.email
    from Conf.notifications_email_address
    subject "#{Conf.sitename} - #{friend_name} has requested to be your friend"
    
    body :user => user,
         :friend_name => friend_name,
         :friendship => friendship,
         :base_url => base_url,
         :target => user
  end
  
  def membership_invite(user, network, membership, base_url)
    recipients user.email
    from Conf.notifications_email_address
    subject "#{Conf.sitename} - you have been invited to join the #{network.title} Group"
    
    body :user => user,
         :network => network,
         :membership => membership,
         :base_url => base_url,
         :target => user
  end
  
  def membership_request(requestor, network, membership, base_url)
    recipients network.owner.email
    from Conf.notifications_email_address
    subject "#{Conf.sitename} - #{requestor.name} would like to join the #{network.title} Group"
    
    body :user => network.owner,
         :network => network,
         :base_url => base_url,
         :membership => membership,
         :requestor => requestor,
         :target => network.owner
  end
  
  def auto_join_group(member, network, base_url)
    recipients network.owner.email
    from Conf.notifications_email_address
    subject "#{Conf.sitename} - #{member.name} has joined the #{network.title} Group"
    
    body :name => network.owner.name,
         :network => network,
         :base_url => base_url,
         :member_name => member.name,
         :target => network.owner
  end
  
  def new_message(message, base_url)
    recipients message.u_to.email
    from Conf.notifications_email_address
    subject "#{Conf.sitename} - #{message.u_from.name} has sent you a message"
    
    body :name => message.u_to.name,
         :username => message.u_to.username,
         :from_name => message.u_from.name,
         :base_url => base_url,
         :subject => message.subject,
         :message_id => message.id,
         :target => message.u_to
  end

end
