# myExperiment: config/initializers/service_deprecation_watcher.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

if ActiveRecord::Base.connection.table_exists?('delayed_jobs')
  Delayed::Worker.backend = :active_record

  unless Delayed::Job.exists?(:handler => ServiceDeprecationJob.new.to_yaml)
    Delayed::Job.enqueue(ServiceDeprecationJob.new, 1, 5.minutes.from_now)
  end
end
