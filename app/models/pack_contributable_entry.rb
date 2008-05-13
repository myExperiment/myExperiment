# myExperiment: app/models/pack_contributable_entry.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackContributableEntry < ActiveRecord::Base
  belongs_to :pack
  
  belongs_to :contributable, :polymorphic => true
  
  belongs_to :user
  
  # This method gets the specific version referred to (if 'contributable_version' is set).
  # Returns nil if cannot find the specified version.
  # Returns the contributable version object if specified version is found (BUT NOTE this object is not a 'contributable' itself and thus cannot be treated as such).
  # Returns the contributable object if no contributable_version is set.
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
end
