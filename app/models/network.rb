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
  has_many :workflows, :as => :contributor
  
  acts_as_solr(:fields => [ :title, :unique_name, :owner_name, :description, :tag_list ],
               :include => [ :comments ]) if SOLR_ENABLE

  format_attribute :description
  
  def self.recently_created(limit=5)
    self.find(:all, :order => "created_at DESC", :limit => limit)
  end
  
  # returns groups with most members
  # the maximum number of results is set by #limit#
  def self.most_members(limit=10)
    self.find_by_sql("SELECT n.* FROM networks n JOIN memberships m ON n.id = m.network_id WHERE m.user_established_at IS NOT NULL AND m.network_established_at IS NOT NULL GROUP BY m.network_id ORDER BY COUNT(m.network_id) DESC, n.title LIMIT #{limit}")
  end
  
  # returns groups with most shared items
  # the maximum number of results is set by #limit#
  def self.most_shared_items(limit=10)
    self.find_by_sql("SELECT n.* FROM networks n JOIN permissions perm ON n.id = perm.contributor_id AND perm.contributor_type = 'Network' JOIN policies p ON perm.policy_id = p.id JOIN contributions c ON p.id = c.policy_id GROUP BY perm.contributor_id ORDER BY COUNT(perm.contributor_id) DESC, n.title LIMIT #{limit}")
  end
  
  validates_associated :owner
  
  validates_presence_of :user_id, :title
  
  # bugfix. after unique_name has been set, if you un-set it, Rails throws an error!
  validates_uniqueness_of :unique_name, :if => Proc.new { |network| !(network.unique_name.nil? or network.unique_name.empty?) }
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  alias_method :contributor, :owner

  def label
    return title
  end

  def owner?(userid)
    user_id.to_i == userid.to_i
  end
  
  def owner_name
    owner.name
  end
                          
  # announcements belonging to the group;
  #
  # "announcements_public" are just the public announcements;
  # and there is no reason for filtering "private" ones, as
  # those who can see private announcements can see all, including public ones
  has_many :announcements, # all - public and private
           :class_name => "GroupAnnouncement",
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_many :announcements_public,
           :class_name => "GroupAnnouncement",
           :conditions => ["public = ?", true],
           :order => "created_at DESC",
           :dependent => :destroy
  
  def announcements_for_user(user)
    if user.is_a?(User) && self.member?(user.id)
      return self.announcements
    else
      return self.announcements_public
    end
  end
  
  def announcements_in_public_mode_for_user(user)
    return (!user.is_a?(User) || !self.member?(user.id))
  end
  
  # memberships
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
  
  # Finds all the contributions that have been explicitly shared via Permissions
  def shared_contributions
    list = []
    self.permissions.each do |p|
      p.policy.contributions.each do |c|
        list << c unless c.nil? || c.contributable.nil?
      end
    end
    list
  end
  
  # Finds all the contributables that have been explicitly shared via Permissions
  def shared_contributables
    c = shared_contributions.map do |c| c.contributable end

    # filter out blogs until they've gone completely
    c.select do |x| x.class != Blog end
  end
end
