# myExperiment: app/models/membership.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Membership < ActiveRecord::Base
  belongs_to :user

  belongs_to :network

  validates_presence_of :user_id, :network_id

#  validates_each :user_id do |model, attr, value|
#    model.errors.add attr, "already member" if model.network.member? value
#  end

  def user_establish!
    if self.user_established_at.nil?
      return update_attribute(:user_established_at, Time.now)
    else
      return false
    end
  end

  def network_establish!
    if self.network_established_at.nil?
      return update_attribute(:network_established_at, Time.now)
    else
      return false
    end
  end

  def accept!
    unless accepted?
      if self.user_established_at.nil?
        self.user_establish!
      end
      if self.network_established_at.nil?
        self.network_establish!
      end
      return true
    else
      return false
    end
  end

  def accepted?
    self.user_established_at != nil and self.network_established_at != nil
  end

  def accepted_at

    user_established_at    = self.user_established_at
    network_established_at = self.network_established_at

    return nil if user_established_at.nil? or network_established_at.nil?

    return user_established_at > network_established_at ? user_established_at : network_established_at;

  end
  
  def is_invite?
    if user_established_at.nil?
      return true
    elsif network_established_at.nil?
      return false
    else
      return user_established_at > network_established_at ? true : false
    end
  end

end
