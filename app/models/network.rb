class Network < ActiveRecord::Base
  validates_presence_of :user_id
  
  validates_presence_of :title
  
  validates_uniqueness_of :unique
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  has_many :relationships
  
  # SELF -- child_relation --> relation_id
  # * child = relation_id
  has_and_belongs_to_many :relations,
                          :class_name => "Network",
                          :join_table => :relationships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :relation_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
  
  # network_id -- parent_relation --> SELF
  # * parent = network_id
  # has_and_belongs_to_many :parent_relations,
  #                         :class_name => "Network",
  #                         :join_table => :relationships,
  #                         :foreign_key => :relation_id,
  #                         :association_foreign_key => :network_id,
  #                         :conditions => ["accepted_at < ?", Time.now],
  #                         :order => "accepted_at DESC"
                          
  has_many :memberships
  
  has_and_belongs_to_many :members,
                          :class_name => "User",
                          :join_table => :memberships,
                          :foreign_key => :user_id,
                          :association_foreign_key => :network_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  def member?(user_id, recursive = false)
    if (rel = self.relations).empty? or !recursive
      self.members.include? User.find(user_id)
    else
      rel.each do |r|
        return true if Network.find(r.relation_id).member? user_id, true
      end
      
      false
    end
  end
  
  def relation?(network_id, recursive = false)
    if (rel = self.relations).empty? or !recursive
      n = Network.find(network_id).id
      
      rel.each do |r|
        return true if r.relation_id.to_i == n.to_i
      end
      
      false
    else
      return true if self.relation? network_id, false
      
      rel.each do |r|
        return true if Network.find(r.relation_id).relation? network_id, true
      end
        
      false
    end
  end
  
  def rmembers
    rtn = self.members
    
    self.relations.each do |r|
      rtn = (rtn + Network.find(r.relation_id).rmembers)
    end
    
    rtn.uniq
  end
  
  def members_recursive 
    rmembers
  end
  
  def rrelations
    rtn = self.relations
    
    self.relations.each do |r|
      rtn = (rtn + Network.find(r.relation_id).rrelations)
    end
    
    rtn # no need for uniq (there shouldn't be any loops)
  end
  
  def relations_recursive 
    rrelations
  end
end
