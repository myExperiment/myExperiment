class Profile < ActiveRecord::Base
  belongs_to :user
  
  belongs_to :picture,
             :as => :avatar,
             :foreign_key => :avatar_id
end
