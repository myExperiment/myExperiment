class Profile < ActiveRecord::Base
  validates_associated :owner, :picture
  
  validates_presence_of :user_id
  
  validates_each :picture_id do |record, attr, value|
    # picture_id = nil  => null avatar
    #              n    => Picture.find(n)
    unless value.nil? or value.to_i == 0
      begin
        p = Picture.find(value)
      
        record.errors.add attr, 'invalid image (not owned)' if p.user_id.to_i != record.user_id.to_i
      rescue ActiveRecord::RecordNotFound
        record.errors.add attr, "invalid image (doesn't exist)"
      end
    end
  end
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  belongs_to :picture
end
