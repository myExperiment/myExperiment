class User < ActiveRecord::Base
  validates_uniqueness_of :openid_url
  
  validates_presence_of :name
  
  has_one :profile
  
  has_many :pictures
  
  has_many :friendships
          
  has_and_belongs_to_many :friends,
                          :class_name => "User", 
                          :join_table => :friendships,
                          :foreign_key => :user_id,
                          :association_foreign_key => :friend_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  has_many :memberships
                          
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
end
