require 'acts_as_contributor'

class Network < ActiveRecord::Base
  acts_as_contributor
  
  def related?(other) # other.kind_of? Mib::Act::Contributor
    if other.kind_of? Network
      return relation?(other)
    elsif other.kind_of? User
      return member?(other)
    else
      return false
    end
  end
  
  validates_associated :owner
  
  validates_presence_of :user_id, :title, :unique
  
  validates_uniqueness_of :unique
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  def owner?(userid)
    user_id.to_i == userid.to_i
  end
  
  has_many :relationships,
           :order => "created_at DESC"
           
  has_many :relationships_accepted, #accepted (by me)
           :class_name => "Relationship",
           :conditions => ["accepted_at < ?", Time.now],
           :order => "accepted_at DESC"
  
  has_many :relationships_requested, #unaccepted (by others)
           :class_name => "Relationship",
           :foreign_key => :network_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC"
           
  has_many :relationships_pending, #unaccepted (by me)
           :class_name => "Relationship",
           :foreign_key => :relation_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC"
  
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
  
#  has_and_belongs_to_many :parents,
#                          :class_name => "Network",
#                          :join_table => :relationships,
#                          :foreign_key => :relation_id,
#                          :association_foreign_key => :network_id,
#                          :conditions => ["accepted_at < ?", Time.now],
#                          :order => "accepted_at DESC"
#                          
#  alias_method :original_parents, :parents
#  def parents
#    rtn = []
#    
#    original_parents.each do |r|
#      rtn << Network.find(r.network_id)
#    end
#    
#    return rtn
#  end
                          
  has_many :memberships, #all
           :order => "created_at DESC"
           
  has_many :memberships_accepted, #accepted (by owner of this network)
           :class_name => "Membership",
           :conditions => ["accepted_at < ?", Time.now],
           :order => "accepted_at DESC"
           
  has_many :memberships_pending, #unaccepted (by owner of this network)
           :class_name => "Membership",
           :foreign_key => :network_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC"
  
  has_and_belongs_to_many :members,
                          :class_name => "User",
                          :join_table => :memberships,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  alias_method :original_members, :members
  def members
    rtn = [User.find(owner.id)]
    
    original_members.each do |m|
      rtn << User.find(m.user_id)
    end
    
    return rtn
  end
                          
  def member?(userid)
    # the owner is automatically a member of the network
    return true if owner? userid
    
    members.each do |m|
      return true if m.id.to_i == userid.to_i
    end
    
    return false
  end
  
  def member_recursive?(userid)
    member_r? userid
  end
  
  # alias for member_recursive?
  def member!(userid)
    member_r? userid
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
  def relation!(userid)
    relation_r? userid
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

  def member_r?(userid, depth=0)
    unless depth > @@maxdepth
      return true if member? userid
    
      relations.each do |r|
        return true if r.member_r? userid, depth+1
      end
    end
    
    false
  end
  
  def relation_r?(network_id, depth=0)
    unless depth > @@maxdepth
      return true if relation? network_id
    
      relations.each do |r|
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
