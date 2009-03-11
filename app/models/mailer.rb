class Mailer < ActionMailer::Base

  def feedback(name, subject, content)
    recipients Conf.feedback_email_address
    from Conf.notifications_email_address
    subject "#{Conf.sitename} feedback from #{name}"
    
    body :name => name, 
         :subject => subject, 
         :content => content
  end
  
  def account_confirmation(user, hash, base_url)
    recipients user.unconfirmed_email
    from Conf.notifications_email_address
    subject "Welcome to #{Conf.sitename}. Please activate your account."

    body :name => user.name, 
         :username => user.username, 
         :hash => hash, 
         :base_url => base_url
  end
  
  def forgot_password(user, base_url)
    recipients user.email
    from Conf.notifications_email_address
    subject "#{Conf.sitename} - Reset Password Request"

    body :name => user.name, 
         :username => user.username, 
         :reset_code => user.reset_password_code, 
         :base_url => base_url
         
  end
  
  def update_email_address(user, hash, base_url)
    recipients user.unconfirmed_email
    from Conf.notifications_email_address
    subject "#{Conf.sitename} - Update Email Address on Account"

    body :name => user.name, 
         :username => user.username, 
         :hash => hash, 
         :base_url => base_url,
         :email => user.unconfirmed_email
  end
  
  def invite_new_user(user, email, msg_text, base_url)
    recipients email
    from user.name + "<" + Conf.notifications_email_address + ">"
    subject "Invitation to join #{Conf.sitename}"

    body :name => user.name, 
         :user_id => user.id, 
         :message => msg_text,
         :base_url => base_url
  end

  def group_invite_new_user(user, group, email, msg_text, token, base_url)
    recipients email
    from user.name + "<" + Conf.notifications_email_address + ">"
    subject "Invitation to join group \"#{group.title}\" at #{Conf.sitename}"

    body :name => user.name, 
         :user_id => user.id,
         :group_id => group.id,
         :group_title => group.title,
         :email => email,
         :message => msg_text,
         :token => token,
         :base_url => base_url
  end
  
  def friendship_invite_new_user(user, email, msg_text, token, base_url)
    recipients email
    from user.name + "<" + Conf.notifications_email_address + ">"
    subject "Invitation to become my friend on #{Conf.sitename}"

    body :name => user.name, 
         :user_id => user.id,
         :email => email,
         :message => msg_text,
         :token => token,
         :base_url => base_url
  end

end
