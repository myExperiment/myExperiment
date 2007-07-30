class Picture < ActiveRecord::Base
  validates_presence_of :user_id
  
  validates_presence_of :data
  
  belongs_to :user
             
  has_many :profiles,
           :foreign_key => :picture_id
end
