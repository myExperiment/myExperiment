class Network < ActiveRecord::Base
  validates_presence_of :user_id
  
  validates_presence_of :title
  
  validates_uniqueness_of :unique
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  has_many :relationships
  
  has_and_belongs_to_many :relations,
                          :class_name => "Network",
                          :join_table => :relationships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :relation_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  alias_method :original_relations, :relations
  def relations
    rtn = []
    
    original_relations.each do |r|
      rtn << Network.find(r.relation_id)
    end
    
    return rtn
  end
  
  has_and_belongs_to_many :parents,
                          :class_name => "Network",
                          :join_table => :relationships,
                          :foreign_key => :relation_id,
                          :association_foreign_key => :network_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  alias_method :original_parents, :parents
  def parents
    rtn = []
    
    original_parents.each do |r|
      rtn << Network.find(r.network_id)
    end
    
    return rtn
  end
                          
  has_many :memberships
  
  has_and_belongs_to_many :members,
                          :class_name => "User",
                          :join_table => :memberships,
                          :foreign_key => :user_id,
                          :association_foreign_key => :network_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  alias_method :original_members, :members
  def members
    rtn = []
    
    original_members.each do |m|
      rtn << User.find(m.user_id)
    end
    
    return rtn
  end
                          
  def member?(user_id)
    members.each do |m|
      return true if m.user_id.to_i == user_id.to_i
    end
    
    return false
  end
  
  def member_recursive?(user_id)
    member_r? user_id
  end
  
  # alias for member_recursive?
  def member!(user_id)
    member_r? user_id
  end
  
  def relation?(network_id)
    relations.each do |r|
      return true if r.id.to_i == network_id.to_i
    end
    
    false
  end
  
  def relation_recursive?(network_id)
    relation_r? network_id
  end
  
  # alias for relation_recursive?
  def relation!(user_id)
    relation_r? user_id
  end
  
  def members_recursive
    members_r
  end
  
  # alias for members_recursive
  def members!
    members_r
  end
  
  def relations_recursive
    relations_r
  end
  
  # alias for relations_recursive
  def relations!
    relations_r
  end
  
protected

  def member_r?(user_id, depth=0)
    unless depth > @@maxdepth
      return true if member? user_id
    
      self.relations.each do |r|
        return true if r.member_r? user_id, depth+1
      end
    end
    
    false
  end
  
  def relation_r?(network_id, depth=0)
    unless depth > @@maxdepth
      return true if relation? user_id
    
      self.relations.each do |r|
        return true if r.relation_r? network_id, depth+1
      end
    end
    
    false
  end
  
  def members_r(depth=0)
    unless depth > @@maxdepth
      rtn = members
    
      relations.each do |r|
         rtn = (rtn + r.members_r(depth+1))
      end
    
      return rtn.uniq
    end
    
    []
  end
  
  def relations_r(depth=0)
    unless depth > @@maxdepth
      rtn = relations
    
      relations.each do |r|
        rtn = (rtn + r.relations_r(depth+1))
      end
    
      return rtn # no need for uniq (there shouldn't be any loops)
    end
    
    []
  end
  
private
  
  @@maxdepth = 7 # maximum level of recursion for depth first search
end
