# myExperiment: app/models/experiment.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class Experiment < ActiveRecord::Base
  
  belongs_to :contributor, :polymorphic => true
  validates_presence_of :contributor
  
  has_many :jobs, :dependent => :destroy, :order => "created_at DESC"
  
  format_attribute :description
  
  validates_presence_of :title
  
  def self.default_title(user)
    s = "Experiment_#{Time.now.strftime('%Y%m%d-%H%M')}"
    s = s + "_#{user.name}" if user
    return s
  end
  
  def self.find_by_contributor(contributor_type, contributor_id)
    Experiment.find(:all, :conditions => ["contributor_type = ? AND contributor_id = ?", contributor_type, contributor_id])
  end
  
  def self.find_by_groups(user)
    return nil unless user.is_a?(User)
    
    experiments = []
    user.all_networks.each do |n|
      experiments = experiments + Experiment.find_by_contributor('Network', n.id)
    end
    
    return experiments
  end
  
  def self.for_user(user)
    return [ ] if user.nil? or !user.is_a?(User)
    
    # Return the Experiments that are owned by the user, and are owned by groups that the user is a part of.
    experiments = Experiment.find_by_contributor('User', user.id)
    return experiments + Experiment.find_by_groups(user)
  end
  
  # Note: at the moment (Feb 2008), Experiments (and associated Jobs) are private to the owner, if a User owns it, 
  # OR accessible by all members of a Group, if a Group owns it. 
  def authorized?(action_name, c_utor=nil)
    return false if c_utor.nil?
    
    # Cannot ask authorization for a 'Network' contributor
    return false if c_utor.class.to_s == 'Network' 
    
    case self.contributor_type.to_s
    when "User"
      return self.contributor_id.to_i == c_utor.id.to_i
    when "Network"
      return self.contributor.member?(c_utor.id)
    else
      return false
    end 
  end
end
