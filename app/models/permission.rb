# myExperiment: app/models/permission.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Permission < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :policy
  
  validates_presence_of :contributor
  validates_presence_of :policy
  
  before_create :check_duplicate
  
  # ==== Levels ====
  # Level 0 -> View = true; Download = false; Edit = false;
  # Level 1 -> View = true; Download = true; Edit = false;
  # Level 2 -> View = true; Download = true; Edit = true;
  
  def level
    if self.view and self.download and self.edit
      return 2
    elsif self.view and self.download
      return 1
    else
      return 0 
    end
  end
  
  def set_level!(lvl)
    case lvl
    when "2"
      self.view = true
      self.download = true
      self.edit = true
      self.save
    when "1"
      self.view = true
      self.download = true
      self.edit = false
      self.save
    when "0"
      self.view = true
      self.download = false
      self.edit = false
      self.save
    end
  end
  
protected
  
  def check_duplicate
    if Permission.find(:first, :conditions => ["policy_id = ? AND contributor_type = ? AND contributor_id = ?", self.policy_id, self.contributor_type, self.contributor_id])
      errors.add_to_base("Permission object already exists for this Contributor in the parent Policy.")
      return false
    else
      return true
    end
  end

end
