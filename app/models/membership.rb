# myExperiment: app/models/membership.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Membership < ActiveRecord::Base

  attr_accessible :user_id, :network_id, :message, :invited_by

  belongs_to :user

  belongs_to :network

  belongs_to :invited_by, :class_name => "User", :foreign_key => "inviter_id"

  validates_presence_of :user_id, :network_id

  validate :membership_allowed, :on => :create

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

      Activity.create_activities(:subject => user, :action => 'create', :object => self)

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

  private

  def membership_allowed
    #Can only invite people in a closed group if you're an administrator
    if self.network.invitation_only? && !self.network.administrators.include?(self.invited_by)
      errors.add(:base, "This group is not open to membership requests.")
    end
  end

end
