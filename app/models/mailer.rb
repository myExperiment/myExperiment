class Mailer < ActionMailer::Base

  def feedback(name, subject, content)
    #recipients "dgc@ecs.soton.ac.uk"
    #recipients "jits@cs.man.ac.uk"
    recipients "bugs@myexperiment.org"
    from "notification@mail.myexperiment.com"
    subject "myExperiment feedback from #{name}"
    body :name => name, :subject => subject, :content => content
  end
  
  def confirmation_email(user, hash, base_url)
    # email header info MUST be added here
    @recipients = user.unconfirmed_email
    @from = "notification@mail.myexperiment.com"
    @subject = "Welcome to myExperiment. Please activate your account."

    # email body substitutions go here
    @body["name"] = user.name
    @body["username"] = user.username
    @body["hash"] = hash
    @body["base_url"] = base_url
  end
  
  def forgot_password(user, base_url)
    # email header info MUST be added here
    @recipients = user.email
    @from = "notification@mail.myexperiment.com"
    @subject = "myExperiment - Reset Password Request"
    @sent_on = Time.now

    # email body substitutions go here
    @body["name"] = user.name
    @body["username"] = user.username
    @body["reset_code"] = user.reset_password_code
    @body["base_url"] = base_url
  end

end
