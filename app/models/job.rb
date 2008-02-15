# myExperiment: app/models/job.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class Job < ActiveRecord::Base
  
  belongs_to :runnable, :polymorphic => true
  validates_presence_of :runnable
  
  belongs_to :runner, :polymorphic => true
  validates_presence_of :runner
  
  belongs_to :experiment
  validates_presence_of :experiment
  
  format_attribute :description
  
  validates_presence_of :title
  
  serialize :inputs_data, Hash
  
  def authorized?(action_name, c_utor=nil)
    # Use authorization logic from parent Experiment
    return self.experiment.authorized?(action_name, c_utor)
  end
  
  def errors
    @errors ||= [ ]
  end
  
  def allow_run?
    self.job_uri.blank? and self.submitted_at.blank?
  end
  
  def save_inputs(inputs)
    unless inputs.is_a?(Hash)
      error.add("Internal error: the inputs need to be in a Hash!")
      return false
    end
    
    if allow_run?
      self.inputs_data = inputs
      self.save!
    else
      error.add("Cannot save inputs now - Job has already been submitted.")
      return false
    end
    
    return true
  end
  
  def submit_and_run
    errors.clear
    success = true
    
    if allow_run?
      
      begin
        
        # Only continue if runner service is valid
        unless runner.service_valid?
          errors.add("The #{humanize self.runner_type} is invalid or inaccessible. Please check the settings you have registered for this Runner.")
          success = false
        end
        
        # Ask the runner for the uri for the runnable object on the service
        # (should submit the object to the service if required)
        remote_runnable_uri = runner.get_remote_runnable_uri(self.runnable_type, self.runnable_id, self.runnable_version)
        
        if remote_runnable_uri
          # Submit inputs (if available) to runner service
          unless self.inputs_data.blank?
            self.inputs_uri = runner.submit_inputs(self.inputs_data)
            self.save!
          end
          
          # Submit the job to the runner, which should begin to execute it, then get status
          self.job_uri = runner.submit_job(remote_runnable_uri, self.inputs_uri)
          self.submitted_at = Time.now
          self.last_status = runner.get_job_status(self.job_uri)
          self.last_status_at = Time.now
          self.save!
        else
          errors.add("Failed to submit the runnable item to the runner service. The item might not exist anymore or access may have been denied at the service.")
          success = false
        end
        
      rescue Exception => ex
        errors.add("An exception has occurred whilst submitting and running this job: #{ex}")
        success = false
      end
      
    else
      errors.add("This Job has already been submitted and cannot be rerun.")
      success = false;
    end
    
    return success
    
  end
  
  def last_status
    begin
      self.last_status = runner.get_job_status(self.job_uri)
      self.last_status_at = Time.now
      self.save
    rescue
    end
    
    return self[:last_status]
  end
  
protected
  
end
