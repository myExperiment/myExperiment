# myExperiment: lib/service_deprecation_job.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

class ServiceDeprecationJob
  def perform
    Rails.logger.info("Checking for workflows with deprecated services...")
    DeprecationEvent.all.each do |event|
      if event.date.past?
        event.affected_workflows.each do |workflow|
          unless workflow.curation_events.exists?(:category => 'decommissioned services')
            Rails.logger.info("Workflow #{workflow.id} has deprecated services (Deprecation Event #{event.id})")
            details = "Deprecation Event #{event.id}: #{event.details}"
            CurationEvent.create(:category => 'decommissioned services', :object => workflow, :details => details)
          end
        end
      end
    end

    # Do it again
    Delayed::Job.enqueue(ServiceDeprecationJob.new, 1, 1.day.from_now)
  end
end