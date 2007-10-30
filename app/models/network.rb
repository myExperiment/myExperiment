##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

require 'acts_as_contributor'

class Network < ActiveRecord::Base
  acts_as_contributor
  
  has_many :blobs, :as => :contributor
  has_many :blogs, :as => :contributor
  has_many :forums, :as => :contributor
  has_many :workflows, :as => :contributor
  
  acts_as_ferret :fields => { :title => { :store => :yes, :index => :untokenized }, 
                              :unique_name => { :store => :yes }, 
                              :owner_name => { :store => :yes },
                              :description => { :store => :yes } ,
                              :tag_list => { :store => :yes } }
  
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
           
  has_many :memberships_accepted, #accepted (by owner of this network)
           :class_name => "Membership",
           :conditions => "accepted_at IS NOT NULL",
           :order => "accepted_at DESC",
           :dependent => :destroy
           
  has_many :memberships_pending, #unaccepted (by owner of this network)
           :class_name => "Membership",
           :foreign_key => :network_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_and_belongs_to_many :members,
                          :class_name => "User",
                          :join_table => :memberships,
                          :conditions => "accepted_at IS NOT NULL",
                          :order => "accepted_at DESC"
                          
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
