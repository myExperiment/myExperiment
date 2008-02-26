# myExperiment: app/models/taverna_enactor.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_runner'
require 'enactor/client'
require 'document/data'
require 'document/report'

class TavernaEnactor < ActiveRecord::Base
  
  acts_as_runner
  
  belongs_to :contributor, :polymorphic => true
  validates_presence_of :contributor
  
  validates_presence_of :username
  validates_presence_of :crypted_password
  validates_presence_of :url
  validates_presence_of :title
  
  encrypts :password, :mode => :symmetric, :key => SYM_ENCRYPTION_KEY
  
  def self.find_by_contributor(contributor_type, contributor_id)
    TavernaEnactor.find(:all, :conditions => ["contributor_type = ? AND contributor_id = ?", contributor_type, contributor_id])
  end
  
  def self.for_user(user)
    return [ ] if user.nil?
    
    # Return the runners that are owned by the user, or are owned by groups that the user is a part of.
    owned_runners = TavernaEnactor.find_by_contributor('User', user.id)
    group_runners = []
    user.all_networks.each do |n|
      group_runners = group_runners + TavernaEnactor.find_by_contributor('Network', n.id)
    end
    
    return owned_runners + group_runners
  end
  
  # Note: at the moment (Feb 2008), updates and deletes are only allowed by the creator of the TavernaEnactor 
  # OR the administrator of the Group that owns the TavernaEnactor.
  # For all other actions, only creator OR members of the Group that owns the TavernaEnactor are authorized.
  def authorized?(action_name, c_utor=nil)
    return false if c_utor.nil?
    
    # Cannot ask authorization for a 'Network' contributor
    return false if c_utor.class.to_s == 'Network'
    
    case self.contributor_type.to_s
    when "User"
      return self.contributor_id.to_i == c_utor.id.to_i
    when "Network"
      if ['edit','update','delete'].include?(action_name.downcase)
        return self.contributor.owner?(c_utor.id)
      else
        return self.contributor.member?(c_utor.id)
      end
    else
      return false
    end
  end
  
  def service_valid?
    service_client.service_valid?
  end
  
  def get_remote_runnable_uri(runnable_type, runnable_id, runnable_version)
    return nil unless ['Workflow'].include? runnable_type
    
    if (r = RemoteWorkflow.find(:first, :conditions => ["workflow_id = ? AND workflow_version = ? AND taverna_enactor_id = ?", runnable_id, runnable_version, self.id]))
      unless service_client.workflow_exists?(r.workflow_uri)
        workflow = Workflow.find_version(runnable_id, runnable_version)
        
        if workflow
          r.workflow_uri = service_client.upload_workflow(workflow.scufl)
          r.save
        else
          return nil
        end
      end
    else
      workflow = workflow = Workflow.find_version(runnable_id, runnable_version)
      
      if workflow
        workflow_uri = service_client.upload_workflow(workflow.scufl)
        r = RemoteWorkflow.create(:workflow_id => runnable_id,
                                  :workflow_version => runnable_version,
                                  :taverna_enactor_id => self.id,
                                  :workflow_uri => workflow_uri)
      else
        return nil
      end
    end
    
    return r.workflow_uri
  end
  
  def submit_inputs(hash)
    # Translate to format required (ie: key => Data::Document)
    inputs_hash = { }
    hash.each do |k,v|
      inputs_hash[k] = Document::Data.new(v)
    end
    service_client.upload_data(inputs_hash)
  end
  
  def submit_job(remote_runnable_uri, inputs_uri)
    service_client.submit_job(remote_runnable_uri, inputs_uri)
  end
  
  def get_job_status(job_uri)
    service_client.get_job_status(job_uri)
  end
  
  def get_job_report(job_uri)
    service_client.get_job_report(job_uri)
  end
  
  def get_job_started_at(job_uri)
    service_client.get_job_created_date(job_uri)
  end
  
  def get_job_completed_at(job_uri, current_status)
    if verify_job_finished?(current_status)
      return service_client.get_job_modified_date(job_uri)
    else
      return nil
    end
  end
  
  def get_job_outputs_uri(job_uri)
    service_client.get_job_outputs_url(job_uri)
  end
  
  def get_job_outputs_xml(job_uri)
    service_client.get_job_outputs_doc(job_uri)
  end
  
  def get_job_outputs(job_uri)
    service_client.get_job_outputs(job_uri)
  end
  
  def verify_job_completed?(current_status)
    return current_status == 'COMPLETE'
  end
  
  def verify_job_finished?(current_status)
    return Enactor::Status.finished?(current_status)
  end
  
protected
  
  # Lazy loading of enactor service client.
  def service_client
    @client ||= Enactor::Client.new(self.url, self.username, self.crypted_password.decrypt)
  end
end
