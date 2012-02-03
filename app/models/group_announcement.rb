class GroupAnnouncement < ActiveRecord::Base
  belongs_to :network
  belongs_to :user
  
  validates_presence_of :title
  validates_presence_of :user_id
  validates_presence_of :network_id
  
  format_attribute :body
  
  before_save :check_admin # this is done in addition to check in the controller 
  
  def check_admin
    if !self.user_id.blank? and self.network.member?(self.user_id)
      return true
    else
      errors.add_to_base("Only group administrators are allowed to create new announcements!")
      return false
    end
  end
  
end
