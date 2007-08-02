class User < ActiveRecord::Base
  validates_uniqueness_of :openid_url
  
  validates_presence_of :openid_url, :name
  
  has_one :profile
  
  has_many :pictures
  
  # SELF --> friendship --> Friend
  has_many :friendships_completed, # accepted (by others)
           :class_name => "Friendship",
           :foreign_key => :user_id,
           :conditions => ["accepted_at < ?", Time.now],
           :order => "created_at DESC"
  
  # SELF --> friendship --> Friend
  has_many :friendships_requested, #unaccepted (by others)
           :class_name => "Friendship",
           :foreign_key => :user_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC"
           
  # Friend --> friendship --> SELF
  has_many :friendships_accepted, #accepted (by me)
           :class_name => "Friendship",
           :foreign_key => :friend_id,
           :conditions => ["accepted_at < ?", Time.now],
           :order => "accepted_at DESC"
           
  # Friend --> friendship --> SELF
  has_many :friendships_pending, #unaccepted (by me)
           :class_name => "Friendship",
           :foreign_key => :friend_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC"
           
  def friendships
    (friendships_completed + friendships_requested + friendships_accepted + friendships_pending).sort do |a, b|
      b.created_at <=> a.created_at
    end
  end
           
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
  
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
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
                          
  has_many :memberships, #all
           :order => "created_at DESC"
           
  has_many :memberships_accepted, #accepted (by others)
           :class_name => "Membership",
           :foreign_key => :user_id,
           :conditions => ["accepted_at < ?", Time.now],
           :order => "accepted_at DESC"
  
  has_many :memberships_requested, #unaccepted (by others)
           :class_name => "Membership",
           :foreign_key => :user_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC"
           
  def memberships_pending
    rtn = []
    
    networks_owned.each do |n|
      rtn.concat n.memberships_pending
    end
    
    return rtn
  end
  
  def relationships_pending
    rtn = []
    
    networks_owned.each do |n|
      rtn.concat n.relations_pending
    end
    
    return rtn
  end
           
  has_many :messages_sent,
           :class_name => "Message",
           :foreign_key => :from,
           :order => "created_at DESC"
           
  has_many :messages_inbox,
           :class_name => "Message",
           :foreign_key => :to,
           :order => "created_at DESC"
           
  has_many :messages_unread,
           :class_name => "Message",
           :foreign_key => :to,
           :conditions => "read_at IS NULL",
           :order => "created_at DESC"
           
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
