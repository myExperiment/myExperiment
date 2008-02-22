# myExperiment: app/models/experiment.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class Experiment < ActiveRecord::Base
  
  belongs_to :contributor, :polymorphic => true
  validates_presence_of :contributor
  
  has_many :jobs, :dependent => :destroy
  
  format_attribute :description
  
  validates_presence_of :title
  
  def self.find_by_contributor(contributor_type, contributor_id)
    Experiment.find(:all, :conditions => ["contributor_type = ? AND contributor_id = ?", contributor_type, contributor_id])
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
