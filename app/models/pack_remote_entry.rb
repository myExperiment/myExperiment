# myExperiment: app/models/pack_remote_entry.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackRemoteEntry < ActiveRecord::Base
  belongs_to :pack
  validates_presence_of :pack
  
  validates_presence_of :uri
  
  belongs_to :user
  validates_presence_of :user
  
  validates_presence_of :title
  
  before_create :check_unique

  def check_unique
    if PackRemoteEntry.find(:first, :conditions => ["pack_id = ? AND uri = ?", self.pack_id, self.uri])
      errors.add_to_base("This external link already exists in the pack")
      return false
    else
      return true
    end
  end
end
