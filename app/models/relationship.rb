class Relationship < ActiveRecord::Base
  validates_presence_of :network_id
  
  validates_presence_of :relation_id
  
  belongs_to :network
  
  belongs_to :relation,
             :class_name => "Network",
             :foreign_key => :relation_id
             
  def accept!
    update_attribute :accepted_at, Time.now
  end

  def accepted?
    self.accepted_at != nil
  end
end
