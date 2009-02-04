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
end
