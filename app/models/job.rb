# myExperiment: app/models/job.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'rexml/document'

class Job < ActiveRecord::Base
  
  belongs_to :runnable, :polymorphic => true
  validates_presence_of :runnable
  validates_presence_of :runnable_version
  
  belongs_to :runner, :polymorphic => true
  validates_presence_of :runner
  
  belongs_to :experiment
  validates_presence_of :experiment
  
  belongs_to :user
  validates_presence_of :user
  
  format_attribute :description
  
  validates_presence_of :title
  
  serialize :inputs_data
  
  def authorized?(action_name, c_utor=nil)
    # Use authorization logic from parent Experiment
    return self.experiment.authorized?(action_name, c_utor)
  end
  
  def run_errors
    @run_errors ||= [ ]
  end
  
  def allow_run?
    self.job_uri.blank? and self.submitted_at.blank?
  end
  
  def submit_and_run!
    run_errors.clear
    success = true
    
    if allow_run?
      
      begin
        
        # Only continue if runner service is valid
        unless runner.service_valid?
          run_errors << "The #{self.runner_type.humanize} is invalid or inaccessible. Please check the settings you have registered for this Runner."
          success = false
        else        
          # Ask the runner for the uri for the runnable object on the service
          # (should submit the object to the service if required)
          remote_runnable_uri = runner.get_remote_runnable_uri(self.runnable_type, self.runnable_id, self.runnable_version)
          
          if remote_runnable_uri
            # Submit inputs (if available) to runner service
            unless self.inputs_data.nil?
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
            run_errors << "Failed to submit the runnable item to the runner service. The item might not exist anymore or access may have been denied at the service."
            success = false
          end
        end
        
      rescue Exception => ex
        run_errors << "An exception has occurred whilst submitting and running this job: #{ex}"
        puts ex
        puts ex.backtrace
        success = false
      end
      
    else
      run_errors << "This Job has already been submitted and cannot be rerun."
      success = false;
    end
    
    return success
    
  end
  
  def refresh_status!
    begin
      if self.job_uri
        self.last_status = runner.get_job_status(self.job_uri)
        self.last_status_at = Time.now
        
        unless self.started_at
          self.started_at = runner.get_job_started_at(self.job_uri)
        end
        
        if self.finished?
          unless self.completed_at
            self.completed_at = runner.get_job_completed_at(self.job_uri, self.last_status)
          end
        end
        
        if self.completed?
          unless self.outputs_uri
            self.outputs_uri = runner.get_job_outputs_uri(self.job_uri)
          end
        end
        
        self.save
      end 
    rescue Exception => ex
      puts "ERROR occurred whilst refreshing status for job #{self.job_uri}. Exception: #{ex}"
      puts ex.backtrace
      return false
    end
  end
  
  def inputs_data=(data)
    if allow_run?
      self[:inputs_data] = data
    end
  end
  
  def current_input_type(input_name)
    return 'none' if input_name.blank? or !self.inputs_data or self.inputs_data.empty?
    
    vals = self.inputs_data[input_name]
    
    return 'none' if vals.blank?
    
    if vals.is_a?(Array)
      return 'list'
    else
      return 'single' 
    end
  end
  
  def has_inputs?
    return self.inputs_data
  end
  
  def report
    begin
      if self.job_uri
        return runner.get_job_report(self.job_uri)
      else
        return nil
      end
    rescue Exception => ex
      puts "ERROR occurred whilst fetching report for job #{self.job_uri}. Exception: #{ex}"
      puts ex.backtrace
      return nil
    end
  end
  
  def completed?
    return runner.verify_job_completed?(self.last_status)
  end
  
  def finished?
    return runner.verify_job_finished?(self.last_status)
  end
  
  # Note: this will return outputs in a format as defined by the Runner.
  def outputs_data
    begin
      if completed?
        return runner.get_job_outputs(self.job_uri)
      else
        return nil
      end
    rescue Exception => ex
      puts "ERROR occurred whilst fetching outputs for job #{self.job_uri}. Exception: #{ex}"
      puts ex.backtrace
      return nil
    end
  end
  
  def outputs_as_xml
    begin
      if completed? and (xml_doc = runner.get_job_outputs_xml(self.job_uri))
        return xml_doc.to_s
      else
        return 'Error: could not retrieve outputs XML document.'
      end
    rescue Exception => ex
      puts "ERROR occurred whilst fetching outputs XML for job #{self.job_uri}. Exception: #{ex}"
      puts ex.backtrace
      return nil
    end
  end
  
protected
  
end
