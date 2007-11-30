# myExperiment: app/models/friendship.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Friendship < ActiveRecord::Base
  validates_associated :user, :friend
  
  validates_presence_of :user_id, :friend_id
  
  belongs_to :user
  
  belongs_to :friend,
             :class_name => "User",
             :foreign_key => :friend_id

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
