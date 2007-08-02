class Profile < ActiveRecord::Base
  validates_associated :owner, :picture
  
  validates_presence_of :user_id
  
  validates_each :picture_id do |record, attr, value|
    record.errors.add attr, 'invalid image (not owned)' if Picture.find(value).user_id.to_i != record.user_id.to_i
  end
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  belongs_to :picture
end
