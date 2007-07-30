class User < ActiveRecord::Base
  validates_uniqueness_of :openid_url
  
  validates_presence_of :name
  
  has_one :profile
  
  has_many :pictures
  
  has_many :friendships

  # SELF -- friend --> friend_id
  # * friend = friend_id
  has_and_belongs_to_many :friends,
                          :class_name => "User", 
                          :join_table => :friendships,
                          :foreign_key => :user_id,
                          :association_foreign_key => :friend_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                            
  # user_id -- friend_with_me --> SELF
  # * friend = user_id
  # has_and_belongs_to_many :friends_with_me,
  #                         :class_name => "User", 
  #                         :join_table => :friendships,
  #                         :foreign_key => :friend_id,
  #                         :association_foreign_key => :user_id,
  #                         :conditions => ["accepted_at < ?", Time.now],
  #                         :order => "accepted_at DESC"
                          
  has_many :memberships
                          
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :user_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  has_many :networks_owned,
           :class_name => "Network"

  def foaf?(user_id)
    foaf user_id
  end

protected
           
  def foaf(user_id, depth=0, maxdepth=7)
    unless depth > maxdepth
      (fri = self.friends).each do |f|
        return true if f.friend_id.to_i == user_id.to_i
      end
      
      fri.each do |f|
        return true if User.find(f.friend_id).foaf user_id, depth+1, maxdepth
      end
    end
    
    false
  end
end
