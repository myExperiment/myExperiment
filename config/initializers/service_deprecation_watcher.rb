# myExperiment: config/initializers/service_deprecation_watcher.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'service_deprecation_job'

if ActiveRecord::Base.connection.table_exists?('delayed_jobs')
  unless Delayed::Job.exists?(:handler => ServiceDeprecationJob.new.to_yaml)
    Delayed::Job.enqueue(ServiceDeprecationJob.new, :priority => 1, :run_at => 5.minutes.from_now)
  end
end
