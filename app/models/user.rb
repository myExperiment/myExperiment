# myExperiment: app/models/user.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'digest/sha1'

require 'acts_as_site_entity'
require 'acts_as_contributor'
require 'acts_as_creditor'

require 'write_once_of'

class User < ActiveRecord::Base
  
  has_many :citations, 
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_many :jobs

  has_many :taverna_enactors, :as => :contributor,
              :conditions => ["contributor_type = ?", "User"]

  has_many :experiments, :as => :contributor,
              :conditions => ["contributor_type = ?", "User"]

  has_many :curation_events, :dependent => :destroy

  def self.most_recent(limit=5)
    self.find(:all,
              :order => "users.created_at DESC",
              :limit => limit,
              :conditions => "users.activated_at IS NOT NULL",
              :include => :profile)
            
  end
  
  def self.last_updated(limit=5)
    self.find_by_sql ["SELECT u.*, p.* FROM users u, profiles p WHERE u.id = p.user_id and activated_at IS NOT NULL ORDER BY GREATEST(u.updated_at, p.updated_at) DESC LIMIT ?", limit]
  end
  
  def self.last_active(limit=5)
    self.find(:all,
              :order => "users.last_seen_at DESC",
              :limit => limit,
              :conditions => "users.activated_at IS NOT NULL",
              :include => :profile)
            
  end
  
  # returns packs that have largest number of friends
  # the maximum number of results is set by #limit#
  def self.most_friends(limit=10)
    self.find_by_sql("SELECT u.* FROM users u JOIN friendships f ON (u.id = f.user_id OR u.id = f.friend_id) AND f.accepted_at IS NOT NULL GROUP BY u.id ORDER BY COUNT(u.id) DESC, u.name LIMIT #{limit}")
  end
  
  # returns packs that have largest number of friends
  # the maximum number of results is set by #limit#
  def self.highest_rated(limit=10)
    self.find_by_sql("SELECT u.* FROM ratings r JOIN contributions c ON r.rateable_type = c.contributable_type AND r.rateable_id = c.contributable_id JOIN users u ON c.contributor_type = 'User' AND c.contributor_id = u.id GROUP BY u.id ORDER BY AVG(r.rating) DESC, u.name LIMIT #{limit}")
  end
  
  acts_as_tagger
  acts_as_bookmarker
  
  has_many :ratings,
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_many :comments,
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_many :downloads, 
           :order => "created_at DESC", 
           :dependent => :destroy
  
  has_many :viewings, 
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_many :reviews,
           :order => "updated_at DESC",
           :dependent => :destroy
 
  has_many :client_applications
  
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application]
           
  acts_as_simile_timeline_event(
    :fields => {
      :start       => :created_at,
      :title       => :simile_title,
      :description => :simile_description,
    }
  )
  
  def simile_title
    "#{self.name}"
  end
  
  def simile_description
    if profile and !profile.body.blank?
      "#{profile.body}"
    else
      ''
    end
  end
  
  # BEGIN RESTful Authentication #
  attr_accessor :password
  
  validates_presence_of     :username,                   :if => :not_openid?
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  #validates_length_of       :username, :within => 3..40, :if => :not_openid?
  validates_length_of       :username, :within => 3..40, :if => Proc.new { |user| !user.username.nil? }
  #validates_uniqueness_of   :username, :case_sensitive => false, :if => (Proc.new { |user| !user.username.nil? } and :not_openid?)
  validates_uniqueness_of   :username, :case_sensitive => false, :if => Proc.new { |user| !user.username.nil? }
  before_save               :encrypt_password
  
  validates_format_of       :username,
                            :with => /^[a-z0-9_]*$/,
                            :message => "can only contain characters, numbers and _",
                            :if => Proc.new { |user| !user.username.nil? }
                            
  validates_write_once_of   :username, :on => :update, :if => Proc.new { |user| !user.username.nil? }, :message => "cannot be changed"  
                          
  validates_presence_of     :openid_url, :if => Proc.new { |user| !user.openid_url.nil? }
  validates_uniqueness_of   :openid_url, :if => Proc.new { |user| !user.openid_url.nil? }
  
  if Conf.validate_email_veracity
    validates_email_veracity_of :email
    validates_email_veracity_of :unconfirmed_email
  end
  
  before_validation :cleanup_input
  before_save :check_email_uniqueness
  before_create :check_email_non_openid_conditions  # NOTE: use before_save if you want validation to occur on updates as well. before_create is being used here because of old user base.
  
  # Prevent the "email" field from being set externally (ie: deny write access)
  def email=(new_email)
    errors.add(:email, "cannot be set directly. Must go through the email confirmation mechanism by using the 'unconfirmed_email' attribute first.")
    return false
  end
  
  # Carries out the process of confirming the email address in the "unconfirmed_email" field.
  # Also activates the user if not previously activated.
  def confirm_email!
    unless self.unconfirmed_email.blank?
      
      # BEGIN DEBUG
      logger.debug("Username: #{self.username}")
      logger.debug("Unconfirmed email: #{self.unconfirmed_email}")
      logger.debug("Confirmed email: #{self.email}")
      # END DEBUG
      
      # Note: need to bypass the explicitly defined setter for 'email'
      self[:email] = self.unconfirmed_email
      self.email_confirmed_at = Time.now
      self.unconfirmed_email = nil
      
      # Activate user if not previously activated
      self.activated_at = Time.now unless self.activated?
      
      return self.save
    else
      return false
    end
  end
  
  
  # method is called only once for each user - right after email address is confirmed;
  # 
  # it queries 'pending_invitations' table and moves all requests to relevant tables
  # (i.e. to 'memberships' and 'friendships' - as appropriate);
  # invitations are matched by registered user's email address.
  #
  # NB! This is done by email not token, because the email was updated on registration -
  # to contain the address that was registered, rather than one that was used for invitation!
  def process_pending_invitations!
    invitations = PendingInvitation.find(:all, :conditions => ["email = ?", self.email])
    
    invitations.each do |invite|
      case invite.request_type
        when "membership"
          unless Membership.find_by_user_id_and_network_id(self.id, invite.request_for)
            membership = Membership.new(:user_id => self.id, :network_id => invite.request_for, :created_at => invite.created_at, :network_established_at => invite.created_at, :user_established_at => nil, :message => invite.message)
            membership.save
          end
          invite.destroy
        when "friendship"
          # 'request_for' is used as id of the user, who sent the invitation - this is because
          # for friendships 'request_for' and 'requested_by' are meant to be the same;
          # still 'request_for' captures the idea of the request being directed to a particular user,
          # and we don't really care who sent the actual invitation
          unless Friendship.find_by_user_id_and_friend_id(invite.request_for, self.id)
            friendship = Friendship.new(:user_id => invite.request_for, :friend_id => self.id, :created_at => invite.created_at, :accepted_at => nil, :message => invite.message)
            friendship.save
          end
          invite.destroy
      end
    end
  end
  
  
  # Authenticates a user by their login name OR email and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    return nil if login.blank? or password.blank?
    
    # Either, check for a User with username matching 'login'
    u = find(:first, :conditions => ["username = ?", login])
    
    # Or, check for a User with email address matching 'login'
    unless u
      u = find(:first, :conditions => ["email = ?", login]) 
    end
    
    u && u.activated? && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    e = self.class.encrypt(password, salt)
    
    # Clear password virtual attribute to prevent it from being shown in forms after update
    self.password = nil
    self.password_confirmation = nil #if self.respond_to?(password_confirmation)
    return e
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  # END RESTful Authentication #
  
  def admin?
    return false if self.username.blank?
    return Conf.admins.include?(self.username.downcase)
  end
  
  acts_as_site_entity

  acts_as_contributor
  
  has_many :blobs, :as => :contributor, :dependent => :destroy
  has_many :blogs, :as => :contributor, :dependent => :destroy
  has_many :workflows, :as => :contributor, :dependent => :destroy
  has_many :packs, :as => :contributor, :dependent => :destroy
  
  acts_as_creditor

  acts_as_solr(:fields => [ :name, :tag_list ], :include => [ :profile ]) if Conf.solr_enable

  validates_presence_of :name
  
  has_one :profile,
          :dependent => :destroy
          
  #validates_associated :profile
          
  before_create :create_profile
  
  has_many :pictures,
           :dependent => :destroy
           
  has_many :picture_selections,
           :order => "created_at DESC",
           :dependent => :destroy
           
  def avatar?
    self.profile and !(self.profile.picture_id.nil? or self.profile.picture_id.zero?)
  end
           
  # SELF --> friendship --> Friend
  has_many :friendships_completed, # accepted (by others)
           :class_name => "Friendship",
           :foreign_key => :user_id,
           :conditions => "accepted_at IS NOT NULL",
           :order => "created_at DESC",
           :dependent => :destroy
  
  # SELF --> friendship --> Friend
  has_many :friendships_requested, #unaccepted (by others)
           :class_name => "Friendship",
           :foreign_key => :user_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
           
  # Friend --> friendship --> SELF
  has_many :friendships_accepted, #accepted (by me)
           :class_name => "Friendship",
           :foreign_key => :friend_id,
           :conditions => "accepted_at IS NOT NULL",
           :order => "accepted_at DESC",
           :dependent => :destroy
           
  # Friend --> friendship --> SELF
  has_many :friendships_pending, #unaccepted (by me)
           :class_name => "Friendship",
           :foreign_key => :friend_id,
           :conditions => "accepted_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
           
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
                          :conditions => "accepted_at IS NOT NULL",
                          :order => "accepted_at DESC"
                          
  alias_method :original_friends_of_mine, :friends_of_mine
  def friends_of_mine
    rtn = []
    
    original_friends_of_mine(force_reload = true).each do |f|
      rtn << User.find(f.friend_id)
    end
    
    return rtn
  end
                            
  has_and_belongs_to_many :friends_with_me,
                          :class_name => "User", 
                          :join_table => :friendships,
                          :foreign_key => :friend_id,
                          :association_foreign_key => :user_id,
                          :conditions => "accepted_at IS NOT NULL",
                          :order => "accepted_at DESC"
                          
  alias_method :original_friends_with_me, :friends_with_me
  def friends_with_me
    rtn = []
    
    original_friends_with_me(force_reload = true).each do |f|
      rtn << User.find(f.user_id)
    end
    
    return rtn
  end
  
  def friends
    User.find(:all,
              :select => "users.*",
              :joins => "JOIN friendships f ON (users.id = f.friend_id OR users.id = f.user_id)",
              :conditions => ["(f.user_id = ? OR f.friend_id = ?) AND (f.accepted_at IS NOT NULL) AND (users.id <> ?)", id, id, id],
              :order => "lower(users.name)" )
  end
  
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
                          :conditions => "user_established_at IS NOT NULL AND network_established_at IS NOT NULL",
                          :order => "GREATEST(user_established_at, network_established_at) DESC"
                          
  alias_method :original_networks, :networks
  def networks
    Network.find(:all,
                 :select => "networks.*",
                 :joins => "JOIN memberships m ON (networks.id = m.network_id)",
                 :conditions => ["m.user_id=? AND m.user_established_at is NOT NULL AND m.network_established_at IS NOT NULL", id],
                 :order => "GREATEST(m.user_established_at, m.network_established_at) DESC" )
  end
                          
  has_many :networks_owned,
           :class_name => "Network",
           :dependent => :destroy
                          
  has_many :memberships, #all
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :memberships_accepted, #accepted
           :class_name => "Membership",
           :foreign_key => :user_id,
           :conditions => "user_established_at IS NOT NULL AND network_established_at IS NOT NULL",
           :order => "GREATEST(user_established_at, network_established_at) DESC",
           :dependent => :destroy
  
  has_many :memberships_requested, #unaccepted by network admin
           :class_name => "Membership",
           :foreign_key => :user_id,
           :conditions => "network_established_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
 
  has_many :memberships_invited, #unaccepted by user
           :class_name => "Membership",
           :foreign_key => :user_id,
           :conditions => "user_established_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
           
  def networks_membership_requests_pending(include_group_admin=false)
    rtn = []
    
    networks_admined(include_group_admin).each do |n|
      rtn.concat n.memberships_requested
    end
    
    return rtn
  end
  
  def networks_admined(include_group_admin=false)
    rtn = []

    rtn.concat(networks_owned)

    if include_group_admin
      rtn.concat Network.find(:all,
                   :select => "networks.*",
                   :joins => "JOIN memberships m ON (networks.id = m.network_id)",
                   :conditions => ["m.user_id=? AND m.user_established_at is NOT NULL AND m.network_established_at IS NOT NULL AND m.administrator", id])
    end

    return rtn
  end
                          
  def networks_membership_invites_pending
    rtn = []
    
    networks_owned.each do |n|
      rtn.concat n.memberships_invited
    end
    
    return rtn
  end
  
  def membership_pending?(network_id)
    return( membership_request_pending?(network_id) || membership_invite_pending?(network_id) )
  end
  
  def membership_request_pending?(network_id)
    memberships_requested.each do |f|
      return true if f.network_id.to_i == network_id.to_i  
    end
    
    return false
  end
  
  def membership_invite_pending?(network_id)
    memberships_invited.each do |f|
      return true if f.network_id.to_i == network_id.to_i
    end
    
    return false
  end
  
  
  def all_networks
    self.networks + self.networks_owned
  end
  
  has_many :messages_sent,
           :class_name => "Message",
           :foreign_key => :from,
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :messages_inbox,
           :class_name => "Message",
           :foreign_key => :to,
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :messages_unread,
           :class_name => "Message",
           :foreign_key => :to,
           :conditions => ["read_at IS NULL AND deleted_by_recipient = ?", false],
           :order => "created_at DESC",
           :dependent => :destroy
           
  def friend?(user_id)
    return true if id.to_i == user_id.to_i
    
    friends.each do |f|
      return true if f.id.to_i == user_id.to_i
    end
    
    return false
  end
  
  def friendship_pending?(user_id)
    friendships_requested.each do |f|
      return true if f.friend_id.to_i == user_id.to_i  
    end
    
    friendships_pending.each do |f|
      return true if f.user_id.to_i == user_id.to_i
    end
    
    return false
  end
  
  # as it does matter to which of the two users the actual 'friendship'
  # belongs (i.e. /user/X/friendships/<id> will work, but /user/Y/friendships/<id> will not),
  # need a method which would return params for obtaining a link for the friendship, which works without
  # having any relevance in which the IDs of the friends are supplied as params
  #
  # Returns: an array of 2 elements:
  # 1) the ID of a user (of 2 involved in the 'friendship') who is a 'friend', not an owner of the friendship;
  # 2) the 'friendship' object itself
  def friendship_from_self_id_and_friends_id(friend_id)
    friendship = Friendship.find(:first, :conditions => [ "( (user_id = ? AND friend_id = ?) OR ( user_id = ? AND friend_id = ? ) )", id, friend_id, friend_id, id ] )
    
    if friendship
      return [friend_id, friendship]
    else
      return [nil, nil] # an error state
    end
  end
  
  def email_confirmed?
    not self.email_confirmed_at.blank? and not self.email.blank?
  end
  
  def activated?
    self.activated_at != nil
  end
  
  def not_openid?
    openid_url.blank?
  end
  
  def send_notifications?
    activated? and email_confirmed? and self.receive_notifications
  end
  
  def ratings_for_contributions
    ratings = [ ]
    
    self.contributions.each do |c|
      c.contributable.ratings.each do |r|
        ratings << r
      end
    end
    
    return ratings
  end
  
  # user's average rating for all contributions
  def average_rating_and_count
    result_set = User.find_by_sql("SELECT AVG(r.rating) AS avg_rating, COUNT(r.rating) as rating_count FROM ratings r JOIN contributions c ON r.rateable_type = c.contributable_type AND r.rateable_id = c.contributable_id JOIN users u ON c.contributor_type = 'User' AND c.contributor_id = u.id WHERE u.id = #{self.id.to_s} GROUP BY u.id")
    return [0,0] if result_set.empty?
    return [result_set[0]["avg_rating"], result_set[0]["rating_count"]]
  end

  def send_email_confirmation_email
    Mailer.deliver_account_confirmation(self, email_confirmation_hash)
  end
  
  def send_update_email_confirmation
    Mailer.deliver_update_email_address(self, email_confirmation_hash)
  end

  def email_confirmation_hash
    Digest::SHA1.hexdigest(unconfirmed_email + Conf.secret_word)
  end

protected

  # clean up emails and username before validation
  def cleanup_input
    # BEGIN DEBUG
    logger.debug('BEGIN cleanup_input')
    # END DEBUG
    
    self.unconfirmed_email = User.clean_string(self.unconfirmed_email) unless self.unconfirmed_email.blank?
    self.username = User.clean_string(self.username) unless self.username.blank?
    
    # BEGIN DEBUG
    logger.debug('END cleanup_input')
    # END DEBUG
  end
  
  def check_email_uniqueness
    # BEGIN DEBUG
    logger.debug('BEGIN check_email_uniqueness')
    # END DEBUG
    
    unique = true
    
    unless self.unconfirmed_email.blank? or self.email.blank?
      if self.unconfirmed_email == self.email
        unique = false
        errors.add_to_base("Your current email is already the same as the one provided")
        errors.add(:unconfirmed_email, "")
      end
    end
    
    unless !unique or self.unconfirmed_email.blank?
      user = User.find_by_email(self.unconfirmed_email)
      if user and !(user.id == self.id)
        unique = false
      else
        user2 = User.find_by_unconfirmed_email(self.unconfirmed_email)
        if user2 and !(user2.id == self.id)
          unique = false
        end
      end
      
      unless unique
        errors.add_to_base("The email provided has already been registered (or is awaiting confirmation)")
        errors.add(:unconfirmed_email, "")
      end
    end
    
    # BEGIN DEBUG
    logger.debug('END check_email_uniqueness')
    # END DEBUG
    
    return unique
  end
  
  def check_email_non_openid_conditions
    # BEGIN DEBUG
    logger.debug('BEGIN check_email_non_openid_conditions')
    # END DEBUG
    
    ok = true
    
    if self.not_openid?
      # Then either 'email' or 'unconfirmed_email' (or both) should be set
      if self.unconfirmed_email.blank? and self.email.blank?
        errors.add_to_base("An email address is required")
        ok = false
      end
    end
    
    # BEGIN DEBUG
    logger.debug('END check_email_non_openid_conditions')
    # END DEBUG
    
    return ok
  end
  
  # BEGIN Authentication "before filter"s #
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{username}--") if self.salt.nil?
    self.crypted_password = encrypt(password)
  end
    
  def password_required?
    !username.nil? && (crypted_password.blank? || !password.blank?)
  end
  
  # END Authentication "before filter"s #

  def create_profile
    if self.profile.nil?
      self.profile = Profile.new(:user_id => self.id) 
      
      # BEGIN DEBUG
      #logger.error("ERRORS!") unless self.profile.errors.empty?
      #self.profile.errors.full_messages.each { |e| logger.error(e) }
      # END DEBUG
    end
  end
    
private

  # clean string to remove spaces and force lowercase
  def self.clean_string(string)
    (string.downcase).gsub(" ","")
  end

end

