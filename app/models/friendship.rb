class Friendship < ActiveRecord::Base
  belongs_to :user
  
  belongs_to :user,
             :as => :friend,
             :foreign_key => :friend_id
end
