class Membership < ActiveRecord::Base
  validates_presence_of :user_id
                            
  validates_presence_of :network_id
  
  belongs_to :user
  
  belongs_to :network
  
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
