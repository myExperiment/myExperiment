# myExperiment: test/functional/friendships_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'sunspot_rails'

class Network < ActiveRecord::Base
  
  attr_accessible :title, :unique_name, :new_member_policy, :description, :user_id
  
  acts_as_contributor
  acts_as_creditor
  
  acts_as_site_entity :owner_text => 'Admin'

  acts_as_commentable
  acts_as_taggable
  
  has_many :blobs, :as => :contributor
  has_many :workflows, :as => :contributor
  has_many :policies, :as => :contributor
  has_one  :feed, :as => :context, :dependent => :destroy
  has_many :activities, :as => :context

  if Conf.solr_enable
    searchable do
      text :title, :as => 'title', :boost => 2.0
      text :unique_name
      text :owner_name, :as => 'owner_name'
      text :description, :as => 'description'

      text :tags, :as => 'tag' do
        tags.map { |tag| tag.name }
      end

      text :comments, :as => 'comment' do
        comments.map { |comment| comment.comment }
      end
    end
  end

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

  def owner?(user)
    user_id == user.id
  end
  
  def owner_name
    owner.name
  end

  def name
    title
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
    if user.is_a?(User) && self.member?(user)
      return self.announcements
    else
      return self.announcements_public
    end
  end
  
  def announcements_in_public_mode_for_user(user)
    return (!user.is_a?(User) || !self.member?(user))
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
    explicit_members = User.find(:all,
                                 :select     => "users.*",
                                 :joins      => "JOIN memberships m on (users.id = m.user_id)",
                                 :conditions => [ "m.network_id=? AND m.user_established_at IS NOT NULL AND m.network_established_at IS NOT NULL", id ],
                                 :order      => "GREATEST(m.user_established_at, m.network_established_at) DESC"
                                )
    return incl_owner ? ( [owner] + explicit_members ) : explicit_members
  end
                          
  def member?(user)
    # the owner is automatically a member of the network
    owner?(user) || members.include?(user)
  end
  
  def administrators(incl_owner=true)
    explicit_administrators = User.find(:all,
                                 :select     => "users.*",
                                 :joins      => "JOIN memberships m on (users.id = m.user_id)",
                                 :conditions => [ "m.network_id=? AND m.administrator AND m.user_established_at IS NOT NULL AND m.network_established_at IS NOT NULL", id ],
                                 :order      => "GREATEST(m.user_established_at, m.network_established_at) DESC"
                                )
    return incl_owner ? ( [owner] + explicit_administrators ) : explicit_administrators
  end

  def administrator?(user)
    # the owner is automatically an adminsitrator of the network
    owner?(user) || administrators(false).include?(user)
  end
                          
  # Finds all the contributions that have been explicitly shared via Permissions
  def shared_contributions
    Contribution.find(:all,
                      :select     => "contributions.*",
                      :joins      => "JOIN policies p on (contributions.policy_id = p.id) JOIN permissions e on (p.id = e.policy_id)",
                      :conditions => [ "e.contributor_id=? AND e.contributor_type = 'Network'", id ])
  end
  
  # Finds all the contributables that have been explicitly shared via Permissions
  def shared_contributables
    shared_contributions.map {|c| c.contributable }
  end

  # New member policy
  # Adapter from #3 of: http://zargony.com/2008/04/28/five-tips-for-developing-rails-applications
  NEW_MEMBER_POLICY_OPTIONS = [
                                [:open,"Open to anyone"],
                                [:by_request,"Membership by request"],
                                [:invitation_only,"Invitation only"]
                              ]

  validates_inclusion_of :new_member_policy, :in => NEW_MEMBER_POLICY_OPTIONS.map {|o| o[0]}

  def new_member_policy
    read_attribute(:new_member_policy).to_sym
  end

  def new_member_policy=(value)
    write_attribute(:new_member_policy, value.to_s)
  end

  def open?
    new_member_policy == :open
  end

  def membership_by_request?
    new_member_policy == :by_request
  end

  def invitation_only?
    new_member_policy == :invitation_only
  end

  #Returns the layout defined for this network in settings.yml > layouts:
  def layout_name
    Conf.layouts.each do |k,v|
      if v["network_id"] == id
        return k
      end
    end

    return nil
  end

  def layout
    Conf.layouts[layout_name]
  end

  after_save :update_administrators

  private

  # If owner changes, make old owner into an adminstrator, and delete the new owner's membership status
  #  (as group owners do not have a membership)
  def update_administrators
    if user_id_changed?
      if (user_id)
        Membership.find_by_user_id_and_network_id(user_id, id).try(:destroy) # delete membership of new owner
      end  
      if (user_id_was)
        Membership.new(:user_id => user_id_was, :network_id => id, :invited_by => User.find(user_id)).tap do |m|
          m.administrator = true
          m.save
          m.accept!
        end # create membership for old owner
      end
    end
  end

end
