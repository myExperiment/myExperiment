class GroupAnnouncement < ActiveRecord::Base
  belongs_to :network
  belongs_to :user
  
  validates_presence_of :title
  validates_presence_of :user_id
  validates_presence_of :network_id
  
  format_attribute :body

end
