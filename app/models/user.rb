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
                          
  alias_method :original_friends_of_mine, :friends_of_mine
  def friends_of_mine
    rtn = []
    
    original_friends_of_mine.each do |f|
      rtn << User.find(f.friend_id)
    end
    
    return rtn
  end
                            
  has_and_belongs_to_many :friends_with_me,
                          :class_name => "User", 
                          :join_table => :friendships,
                          :foreign_key => :friend_id,
                          :association_foreign_key => :user_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  alias_method :original_friends_with_me, :friends_with_me
  def friends_with_me
    rtn = []
    
    original_friends_with_me.each do |f|
      rtn << User.find(f.user_id)
    end
    
    return rtn
  end
  
  def friends
    (friends_of_mine + friends_with_me).uniq
  end
                          
  has_many :memberships
                          
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :user_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  alias_method :original_networks, :networks
  def networks
    rtn = []
    
    original_networks.each do |n|
      rtn << Network.find(n.network_id)
    end
    
    return rtn
  end
                          
  has_many :networks_owned,
           :class_name => "Network"
           
  def foaf?(user_id)
    foaf user_id
  end
  
protected

  def foaf(user_id, depth=0)
    unless depth > @@maxdepth
      (fri = friends_of_mine).each do |f|
        return true if f.id.to_i == user_id.to_i
      end
      
      fri.each do |f|
        return true if f.foaf user_id, depth+1
      end
    end
    
    false
  end
  
private
  
  @@maxdepth = 7 # maximum level of recursion for depth first search
end
