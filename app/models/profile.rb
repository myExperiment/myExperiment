class Profile < ActiveRecord::Base
  validates_presence_of :user_id
  
  belongs_to :user
  
  belongs_to :avatar,
             :class_name => "Picture",
             :foreign_key => :picture_id
end
