class Mailer < ActionMailer::Base
  
  NOTIFICATIONS_EMAIL = "notification@mail.myexperiment.com"
  FEEDBACK_EMAIL = "bugs@myexperiment.org"

  def feedback(name, subject, content)
    recipients FEEDBACK_EMAIL
    from NOTIFICATIONS_EMAIL
    subject "myExperiment feedback from #{name}"
    
    body :name => name, 
         :subject => subject, 
         :content => content
  end
  
  def account_confirmation(user, hash, base_url)
    recipients user.unconfirmed_email
    from NOTIFICATIONS_EMAIL
    subject "Welcome to myExperiment. Please activate your account."

    body :name => user.name, 
         :username => user.username, 
         :hash => hash, 
         :base_url => base_url
  end
  
  def forgot_password(user, base_url)
    recipients user.email
    from NOTIFICATIONS_EMAIL
    subject "myExperiment - Reset Password Request"

    body :name => user.name, 
         :username => user.username, 
         :reset_code => user.reset_password_code, 
         :base_url => base_url
         
  end
  
  def update_email_address(user, hash, base_url)
    recipients user.unconfirmed_email
    from NOTIFICATIONS_EMAIL
    subject "myExperiment - Update Email Address on Account"

    body :name => user.name, 
         :username => user.username, 
         :hash => hash, 
         :base_url => base_url,
         :email => user.unconfirmed_email
  end
  
  def invite_new_user(user, email, msg_text, base_url)
    recipients email
    from user.name + "<" + NOTIFICATIONS_EMAIL + ">"
    subject "Invitation to join myExperiment.org"

    body :name => user.name, 
         :user_id => user.id, 
         :message => msg_text,
         :base_url => base_url
  end

  def group_invite_new_user(user, group, email, msg_text, token, base_url)
    recipients email
    from user.name + "<" + NOTIFICATIONS_EMAIL + ">"
    subject "Invitation to join group \"#{group.title}\" at myExperiment.org"

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
    from user.name + "<" + NOTIFICATIONS_EMAIL + ">"
    subject "Invitation to become my friend on myExperiment.org"

    body :name => user.name, 
         :user_id => user.id,
         :email => email,
         :message => msg_text,
         :token => token,
         :base_url => base_url
  end

end
