class Picture < FlexImage::Model
  validates_associated :owner
  
  validates_presence_of :user_id, :data
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  has_many :profiles,
           :foreign_key => :picture_id
           
  def select!
    unless selected?
      owner.profile.update_attribute :picture_id, id
      return true
    else
      return false
    end
  end
  
  def selected?
    owner.profile.picture and owner.profile.picture.id.to_i == id.to_i
  end
end
