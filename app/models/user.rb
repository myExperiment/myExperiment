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

require 'digest/sha1'

require 'acts_as_contributor'

class User < ActiveRecord::Base
  validates_uniqueness_of :openid_url, :allow_nil => true
  
  def self.most_recent(limit=5)
    self.find(:all,
              :order => "created_at DESC",
              :limit => limit)
  end
  
  acts_as_tagger
  
  has_many :downloads
  has_many :viewings
  
  has_many :bookmarks
  
  # BEGIN RESTful Authentication #
  attr_accessor :password
  
  validates_presence_of     :username,                   :if => :not_openid?
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :username, :within => 3..40, :if => :not_openid?
  validates_uniqueness_of   :username, :case_sensitive => false, :if => (Proc.new { |user| !user.username.nil? } and :not_openid?)
  before_save :encrypt_password
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password)
    u = find(:first, :conditions => ["username = ?", username]) # need to get the salt
    
    # use email address as RESTful username
    # unless u
    #   u = find(:first, 
    #            :joins => "LEFT JOIN profiles ON profiles.user_id = users.id",
    #            :conditions => ["profiles.email = ?", username]) 
    #           
    #   u = find(:first, :conditions => ["id = ?", u.id])
    # end
    
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
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
  
  acts_as_contributor
  
  acts_as_ferret :fields => [:openid_url, :name, :username]
  
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
  
  before_create do |u|
    u.profile = Profile.new(:user_id => u.id)
  end
  
  has_many :pictures,
           :dependent => :destroy
           
  # BEGIN SavageBeast #
  include SavageBeast::UserInit
  
  def display_name
    "#{name}"
  end
  
  def email
    "#{profile.email}"
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
    (friends_of_mine + friends_with_me).uniq
  end
  
  has_and_belongs_to_many :networks,
                          :join_table => :memberships,
                          :conditions => "accepted_at IS NOT NULL",
                          :order => "accepted_at DESC"
                          
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
           :dependent => :nullify
                          
  has_many :memberships, #all
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :memberships_accepted, #accepted (by others)
           :class_name => "Membership",
           :foreign_key => :user_id,
           :conditions => "accepted_at IS NOT NULL",
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
  
protected

  # BEGIN Authentication "before filter"s #
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{username}--") if new_record?
    self.crypted_password = encrypt(password)
  end
    
  def password_required?
    not_openid? && (crypted_password.blank? || !password.blank?)
  end

  def not_openid?
    openid_url.blank?
  end
  # END Authentication "before filter"s #

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
  
  @@maxdepth = 7 # maximum level of recursion for depth first search
end
