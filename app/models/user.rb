class User < ActiveRecord::Base
  validates_uniqueness_of :openid_url
  
  validates_presence_of :name
  
  has_one :profile
  
  has_many :pictures
  
  has_many :friendships
          
  has_and_belongs_to_many :friends_of_mine,
                          :class_name => "User", 
                          :join_table => :friendships,
                          :foreign_key => :user_id,
                          :association_foreign_key => :friend_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  has_and_belongs_to_many :friends_with_me,
                          :class_name => "User", 
                          :join_table => :friendships,
                          :foreign_key => :friend_id,
                          :association_foreign_key => :user_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  def friends
    (self.friends_of_mine + self.friends_with_me).uniq
  end
                          
  has_many :memberships
                          
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :user_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  has_many :networks_owned,
           :class_name => "Network"
end
