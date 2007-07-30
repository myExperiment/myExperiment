class Profile < ActiveRecord::Base
  validates_presence_of :user_id
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  belongs_to :avatar,
             :class_name => "Picture",
             :foreign_key => :picture_id
end
