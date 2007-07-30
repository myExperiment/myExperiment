class Picture < ActiveRecord::Base
  validates_presence_of :user_id
  
  validates_presence_of :data
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  has_many :profiles,
           :foreign_key => :picture_id
end
