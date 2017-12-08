# Load the rails application
require File.expand_path('../application', __FILE__)

require 'conf'

# Initialize the rails application
MyExperiment::Application.initialize!

# BELOW COPIED FROM OLD RAILS 2 CONFIG:

# Include your application configuration below

# SMTP configuration

require 'smtp_tls'
require 'authorization'

ActionMailer::Base.smtp_settings = Conf.smtp

class ActiveRecord::Base

  def inhibit_timestamps(&blk)

    initial_value = ActiveRecord::Base.record_timestamps

    begin
      ActiveRecord::Base.record_timestamps = false
      yield
    rescue Exception
      ActiveRecord::Base.record_timestamps = initial_value
      raise
    end

    ActiveRecord::Base.record_timestamps = initial_value
  end
end
