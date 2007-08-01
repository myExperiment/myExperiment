class Membership < ActiveRecord::Base
  validates_presence_of :user_id
                            
  validates_presence_of :network_id
  
  belongs_to :user
  
  belongs_to :network
  
  def accept!
    update_attribute :accepted_at, Time.now
  end

  def accepted?
    self.accepted_at != nil
  end
end
