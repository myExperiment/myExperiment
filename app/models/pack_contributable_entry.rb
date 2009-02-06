# myExperiment: app/models/pack_contributable_entry.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackContributableEntry < ActiveRecord::Base
  belongs_to :pack
  validates_presence_of :pack
  
  belongs_to :contributable, :polymorphic => true
  validates_presence_of :contributable
  
  belongs_to :user
  validates_presence_of :user
  
  before_create :check_unique
  
  before_save :check_version
  
  def check_unique
    if self.contributable_version.blank?
      i = PackContributableEntry.find(:first, :conditions => ["pack_id = ? AND contributable_type = ? AND contributable_id = ? AND contributable_version IS NULL", self.pack_id, self.contributable_type, self.contributable_id]) 
    else
      i = PackContributableEntry.find(:first, :conditions => ["pack_id = ? AND contributable_type = ? AND contributable_id = ? AND contributable_version = ?", self.pack_id, self.contributable_type, self.contributable_id, self.contributable_version])
    end
    
    if i
      errors.add_to_base("This item already exists in the pack")
      return false
    else
      return true
    end
  end
  
  def check_version
    return true if self.contributable_version.blank?
    
    if self.contributable.respond_to?(:find_version)
      unless self.contributable.find_version(self.contributable_version)
        errors.add_to_base('The item version specified could not be found.')
      return false
      end
    else
      # A version has been set, but the contributable doesn't allow versioning, so error.    
      errors.add_to_base('The item version specified could not be found.')
      return false
    end
  end
  
  # This method gets the specific version referred to (if 'contributable_version' is set).
  # - Returns nil if cannot find the specified version.
  # - Returns the contributable version object if specified version is found (BUT NOTE this object is not a 'contributable' itself and thus cannot be treated as such).
  # - Returns the contributable object if no contributable_version is set.
  def get_contributable_version
    if self.contributable_version.blank?
      return self.contributable
    else
      if self.contributable.respond_to?(:find_version)
        return self.contributable.find_version(self.contributable_version)
      else
        return nil
      end
    end
  end
  
  def available?
    return (self.contributable != nil)
  end

  def item_as_list
    return [contributable]
  end
end
