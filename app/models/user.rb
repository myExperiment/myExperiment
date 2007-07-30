class User < ActiveRecord::Base
  has_one :profile
  
  has_many :pictures
  
  has_many :friendships
          
  has_and_belongs_to_many :users,
                          :as => :friends,
                          :join_table => :friendships,
                          :foreign_key => :user_id,
                          :association_foreign_key => :friend_id
                          
  has_many :memberships
                          
  has_and_belongs_to_many :networks,
                          :join_table => :memberships
end
