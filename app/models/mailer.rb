class Mailer < ActionMailer::Base

  def feedback(name, content)
    recipients "dgc@ecs.soton.ac.uk"
    from "myexpmail@gmail.com"
    subject "myExperiment feedback from #{name}"
    body :name => name, :content => content
  end

end
