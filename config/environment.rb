# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
MyExperiment::Application.initialize!

# BELOW COPIED FROM OLD RAILS 2 CONFIG:

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

Mime::Type.register "application/whip-archive", :whip
Mime::Type.register "application/rdf+xml", :rdf
Mime::Type.register "application/zip", :zip

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
