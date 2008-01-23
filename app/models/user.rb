# myExperiment: app/models/user.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'digest/sha1'

require 'acts_as_contributor'
require 'acts_as_creditor'

require 'write_once_of'

class User < ActiveRecord::Base
  
  has_many :citations, 
           :order => "created_at DESC",
           :dependent => :destroy
  
  def self.most_recent(limit=5)
    self.find(:all,
              :order => "created_at DESC",
              :limit => limit,
              :conditions => "activated_at IS NOT NULL")
            
  end
  
  def self.last_updated(limit=5)
    self.find_by_sql ["SELECT u.*, p.* FROM users u, profiles p WHERE u.id = p.user_id and activated_at IS NOT NULL ORDER BY GREATEST(u.updated_at, p.updated_at) DESC LIMIT ?", limit]
  end
  
  acts_as_tagger
  
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
  
  has_many :bookmarks, 
           :order => "created_at DESC",
           :dependent => :destroy
  
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
  
  validates_email_veracity_of :email
  validates_email_veracity_of :unconfirmed_email
  
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
      puts "Username: #{self.username}"
      puts "Unconfirmed email: #{self.unconfirmed_email}"
      puts "Confirmed email: #{self.email}"
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
    return ADMINS.include?(self.username.downcase)
  end
  
  acts_as_contributor
  
  has_many :blobs, :as => :contributor
  has_many :blogs, :as => :contributor
  has_many :forums, :as => :contributor
  has_many :workflows, :as => :contributor
  
  acts_as_creditor

  acts_as_solr(:fields => [ :openid_url, :name, :username, :tag_list ]) if SOLR_ENABLE

  # protected? asks the question "is other protected by me?"
  def protected?(other)
    if other.kind_of? User        # if other is a User...
      return friend?(other.id)    #       ...is other a friend of mine?
    elsif other.kind_of? Network  # if other is a Network...
      return other.member?(id)    #       ...am I a member of other?
    else                          # otherwise...
      return false                #       ...no
    end
  end
  
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
           
  # BEGIN SavageBeast #
  include SavageBeast::UserInit
  
  def display_name
    "#{name}"
  end
  
  # END SavageBeast #
  
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
    (friends_of_mine + friends_with_me).uniq.sort { |a, b|
      a.name <=> b.name
    }
  end
  
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
                          :conditions => "user_established_at IS NOT NULL AND network_established_at IS NOT NULL",
                          :order => "GREATEST(user_established_at, network_established_at) DESC"
                          
  alias_method :original_networks, :networks
  def networks
    rtn = []
    
    original_networks(force_reload = true).each do |n|
      rtn << Network.find(n.network_id)
    end
    
    return rtn
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
           
  def networks_membership_requests_pending
    rtn = []
    
    networks_owned.each do |n|
      rtn.concat n.memberships_requested
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
           :conditions => "read_at IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
           
  def friend?(user_id)
    return true if id.to_i == user_id.to_i
    
    friends.each do |f|
      return true if f.id.to_i == user_id.to_i
    end
    
    return false
  end 
  
  def friend_recursive?(user_id)
    friend_r? user_id
  end
  
  # alias for friend_recursive?
  def friend!(user_id)
    friend_r? user_id
  end
  
  # alias for friend_recursive?
  def foaf?(user_id)
    friend_r? user_id
  end
  
  def friends_recursive
    friends_r_wrapper
  end
  
# alias for friends_recursive
  def friends!
    friends_r_wrapper
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
  
protected

  # clean up emails and username before validation
  def cleanup_input
    # BEGIN DEBUG
    puts 'BEGIN cleanup_input'
    # END DEBUG
    
    self.unconfirmed_email = User.clean_string(self.unconfirmed_email) unless self.unconfirmed_email.blank?
    self.username = User.clean_string(self.username) unless self.username.blank?
    
    # BEGIN DEBUG
    puts 'END cleanup_input'
    # END DEBUG
  end
  
  def check_email_uniqueness
    # BEGIN DEBUG
    puts 'BEGIN check_email_uniqueness'
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
    puts 'END check_email_uniqueness'
    # END DEBUG
    
    return unique
  end
  
  def check_email_non_openid_conditions
    # BEGIN DEBUG
    puts 'BEGIN check_email_non_openid_conditions'
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
    puts 'END check_email_non_openid_conditions'
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
      #puts "ERRORS!" unless self.profile.errors.empty?
      #self.profile.errors.full_messages.each { |e| puts e }
      # END DEBUG
    end
  end
    
  def friend_r?(user_id, depth=0)
    unless depth > @@maxdepth
      return true if friend? user_id
      
      friends.each do |f|
        return true if f.friend_r? user_id, depth+1
      end
    end
    
    false
  end
  
  def friends_r_wrapper
    # removes circular references (friend(self, A) & friend(A, B) & friend(B, self) ==> friend(self, self))
    friends_r.collect { |u| u = (u.id.to_i == id.to_i) ? nil : u }.compact
  end
  
  def friends_r(depth=0)
    unless depth > @@maxdepth
      rtn = friends
    
      friends.each do |r|
         rtn = (rtn + r.friends_r(depth+1))
      end
    
      return rtn.uniq
    end
    
    []
  end
  
private

  # clean string to remove spaces and force lowercase
  def self.clean_string(string)
    (string.downcase).gsub(" ","")
  end
  
  @@maxdepth = 7 # maximum level of recursion for depth first search
end
