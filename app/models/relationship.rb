# myExperiment: app/models/relationship.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Relationship < ActiveRecord::Base
  validates_associated :network, :relation
  
  validates_presence_of :network_id, :relation_id
  
  belongs_to :network
  
  belongs_to :relation,
             :class_name => "Network",
             :foreign_key => :relation_id
             
  def accept!
    unless accepted?
      update_attribute :accepted_at, Time.now
      return true
    else
      return false
    end
  end

  def accepted?
    self.accepted_at != nil
  end
end
