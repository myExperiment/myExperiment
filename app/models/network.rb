# myExperiment: test/functional/friendships_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributor'
require 'acts_as_creditor'

class Network < ActiveRecord::Base
  acts_as_contributor
  acts_as_creditor
  
  acts_as_commentable
  acts_as_taggable
  
  has_many :blobs, :as => :contributor
  has_many :blogs, :as => :contributor
  has_many :forums, :as => :contributor, :dependent => :destroy
  has_many :workflows, :as => :contributor
  
  acts_as_solr(:fields => [ :title, :unique_name, :owner_name, :description, :tag_list ],
               :include => [ :comments ]) if SOLR_ENABLE

  format_attribute :description
  
  def self.recently_created(limit=5)
    self.find(:all, :order => "created_at DESC", :limit => limit)
  end
  
  # protected? asks the question "is other protected by me?"
  def protected?(other)
    if other.kind_of? User        # if other is a User...
      return member?(other.id)    #       ...is other a member of me?
    elsif other.kind_of? Network  # if other is a Network...
      return relation?(other.id)  #       ...is other a child of mine?
    else                          # otherwise...
      return false                #       ...no
    end
  end
  
  validates_associated :owner
  
  validates_presence_of :user_id, :title
  
  # bugfix. after unique_name has been set, if you un-set it, Rails throws an error!
  validates_uniqueness_of :unique_name, :if => Proc.new { |network| !(network.unique_name.nil? or network.unique_name.empty?) }
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  def owner?(userid)
    user_id.to_i == userid.to_i
  end
  
  def owner_name
    owner.name
  end
  
  def authorized?(action_name, contributor=nil)
    return true
  end
  
#  has_many :relationships_completed, #accepted (by others)
#           :class_name => "Relationship",
#           :foreign_key => :network_id,
#           :conditions => ["accepted_at < ?", Time.now],
#           :order => "created_at DESC",
#           :dependent => :destroy
#           
#  has_many :relationships_requested, #unaccepted (by others)
#           :class_name => "Relationship",
#           :foreign_key => :network_id,
#           :conditions => "accepted_at IS NULL",
#           :order => "created_at DESC",
#           :dependent => :destroy
#           
#  has_many :relationships_accepted, #accepted (by me)
#           :class_name => "Relationship",
#           :foreign_key => :relation_id,
#           :conditions => ["accepted_at < ?", Time.now],
#           :order => "accepted_at DESC",
#           :dependent => :destroy
#           
#  has_many :relationships_pending, #unaccepted (by me)
#           :class_name => "Relationship",
#           :foreign_key => :relation_id,
#           :conditions => "accepted_at IS NULL",
#           :order => "created_at DESC",
#           :dependent => :destroy
#
#  def relationships
#    (relationships_completed + relationships_requested + relationships_accepted + relationships_pending).sort do |a, b|
#      b.created_at <=> a.created_at
#    end
#  end
  
  has_and_belongs_to_many :relations,
                          :class_name => "Network",
                          :join_table => :relationships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :relation_id,
                          :conditions => "accepted_at IS NOT NULL",
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
    
#    return rtn
#  end
                          
  has_many :memberships, #all
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :memberships_accepted, #accepted by both parties
           :class_name => "Membership",
           :conditions => "user_established_at IS NOT NULL AND network_established_at IS NOT NULL",
           :order => "GREATEST(user_established_at, network_established_at) DESC",
           :dependent => :destroy
           
  has_many :memberships_requested, #unaccepted by network admin
           :class_name => "Membership",
           :foreign_key => :network_id,
           :conditions => "network_established_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :memberships_invited, #unaccepted by user
           :class_name => "Membership",
           :foreign_key => :network_id,
           :conditions => "user_established_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_and_belongs_to_many :members,
                          :class_name => "User",
                          :join_table => :memberships,
                          :conditions => "user_established_at IS NOT NULL AND network_established_at IS NOT NULL",
                          :order => "GREATEST(user_established_at, network_established_at) DESC"
                          
  alias_method :original_members, :members
  def members(incl_owner=true)
    rtn = incl_owner ? [User.find(owner.id)] : []
    
    original_members(force_reload = true).each do |m|
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
  
  # Finds all the contributions that have been explicitly shared via Permissions
  def shared_contributions
    list = []
    self.permissions.each do |p|
      p.policy.contributions.each do |c|
        list << c
      end
    end
    list
  end
  
  # Finds all the contributables that have been explicitly shared via Permissions
  def shared_contributables
    shared_contributions.map do |c| c.contributable end
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
