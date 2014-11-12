class Mailer < ActionMailer::Base

  helper :application

  def feedback(name, subj, content)
    @name = name
    @subject = subject
    @content = content

    mail(
      :to => Conf.feedback_email_address,
      :from => Conf.notifications_email_address,
      :subject => "#{Conf.sitename} feedback from #{name}: #{subj}"
    )
  end
  
  def account_confirmation(user, hash)
    @name = user.name
    @user = user
    @hash = hash

    mail(
      :to => user.unconfirmed_email,
      :from => Conf.notifications_email_address,
      :subject => "Welcome to #{Conf.sitename}. Please activate your account."
    )
  end
  
  def forgot_password(user)
    @name = user.name
    @user = user
    @reset_code = user.reset_password_code

    mail(
      :to => user.email,
      :from => Conf.notifications_email_address,
      :subject => "#{Conf.sitename} - Reset Password Request"
    )
  end
  
  def update_email_address(user, hash)
    @name = user.name
    @user = user
    @hash = hash
    @email = user.unconfirmed_email

    mail(
      :to => user.unconfirmed_email,
      :from => Conf.notifications_email_address,
      :subject => "#{Conf.sitename} - Update Email Address on Account"
    )
  end
  
  def invite_new_user(user, email, msg_text)
    @name = user.name
    @user_id = user.id
    @message = msg_text

    mail(
      :to => email,
      :from => user.name + "<" + Conf.notifications_email_address + ">",
      :subject => "Invitation to join #{Conf.sitename}"
    )
  end

  def group_invite_new_user(user, group, email, msg_text, token)
    @name = user.name
    @user_id = user.id
    @group_id = group.id
    @group_title = group.title
    @email = email
    @message = msg_text
    @token = token

    mail(
      :to => email,
      :from => user.name + "<" + Conf.notifications_email_address + ">",
      :subject => "Invitation to join group \"#{group.title}\" at #{Conf.sitename}"
    )
  end
  
  def friendship_invite_new_user(user, email, msg_text, token)
    @name = user.name
    @user_id = user.id
    @email = email
    @message = msg_text
    @token = token

    mail(
      :to => email,
      :from => user.name + "<" + Conf.notifications_email_address + ">",
      :subject => "Invitation to become my friend on #{Conf.sitename}"
    )
  end

end
