class Mailer < ActionMailer::Base

  def feedback(name, subject, content)
    #recipients "dgc@ecs.soton.ac.uk"
    #recipients "jits@cs.man.ac.uk"
    recipients "bugs@myexperiment.org"
    from "myexpmail@gmail.com"
    subject "myExperiment feedback from #{name}"
    body :name => name, :subject => subject, :content => content
  end

end
