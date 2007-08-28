class Membership < ActiveRecord::Base
  belongs_to :user
  
  belongs_to :network
  
  validates_presence_of :user_id, :network_id
  
  validates_each :user_id do |model, attr, value|
    model.errors.add attr, "already member" if model.network.member? value
  end
  
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
