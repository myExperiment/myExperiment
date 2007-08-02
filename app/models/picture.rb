class Picture < FlexImage::Model
  validates_associated :owner
  
  validates_presence_of :user_id, :data
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  has_many :profiles,
           :foreign_key => :picture_id
end
