class Picture < ActiveRecord::Base
  belongs_to :user
             
  has_many :profiles,
           :as => :avatar_for,
           :foreign_key => :avatar_id
end
