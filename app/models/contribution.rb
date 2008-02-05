# myExperiment: app/models/contribution.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Contribution < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :contributable, :polymorphic => true
  belongs_to :policy
  
  has_many :downloads,
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :viewings,
           :order => "created_at DESC",
           :dependent => :destroy
           
  # returns the 'most downloaded' Contributions
  # the maximum number of results is set by #limit#
  def self.most_downloaded(limit=10, klass=nil)
    conditions = "downloads_count != 0"
    conditions = ["#{conditions} AND contributable_type = ?", klass] if klass
    
    self.find(:all, 
              :conditions => conditions, 
              :order => "downloads_count DESC", 
              :limit => limit)
  end
  
  # returns the 'most viewed' Contributions
  # the maximum number of results is set by #limit#
  def self.most_viewed(limit=10, klass=nil)
    conditions = "viewings_count != 0"
    conditions = ["#{conditions} AND contributable_type = ?", klass] if klass
    
    self.find(:all, 
              :conditions => conditions,
              :order => "viewings_count DESC", 
              :limit => limit)
  end
  
  # returns the 'most recent' Contributions
  # the maximum number of results is set by #limit#
  def self.most_recent(limit=10, klass=nil)
    conditions = ["contributable_type = ?", klass] if klass
    self.find(:all,
              :conditions => conditions,
              :order => "created_at DESC",
              :limit => limit)
  end
  
  # returns the 'last updated' Contributions
  # the maximum number of results is set by #limit#
  def self.last_updated(limit=10, klass=nil)
    conditions = ["contributable_type = ?", klass] if klass
    self.find(:all,
              :conditions => conditions,
              :order => "updated_at DESC",
              :limit => limit)
  end
  
  # is c_utor authorized to edit the policy for this contribution
  def admin?(c_utor)
    #policy.contributor_id.to_i == c_utor.id.to_i and policy.contributor_type.to_s == c_utor.class.to_s
    policy.admin?(c_utor)
  end
  
  # is c_utor authorized to perform action_name (using the policy)
  def authorized?(action_name, c_utor=nil)
    policy.nil? ? Policy._default(self.contributor, self).authorized?(action_name, self, c_utor) : policy.authorized?(action_name, self, c_utor)
  end
  
  # is c_utor the owner of this contribution
  def owner?(c_utor)
    #contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
    
    case self.contributor_type.to_s
    when "User"
      return (self.contributor_id.to_i == c_utor.id.to_i and self.contributor_type.to_s == c_utor.class.to_s)
    when "Network"
      return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s
    else
      return false
    end
    
    #return (self.contributor_id.to_i == c_utor.id.to_i and self.contributor_type.to_s == c_utor.class.to_s) if self.contributor_type.to_s == "User"
    #return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s == "Network"
    
    #false
  end
  
  # is c_utor the uploader of this contribution
  def uploader?(c_utor)
    #contributable.contributor_id.to_i == c_utor.id.to_i and contributable.contributor_type.to_s == c_utor.class.to_s
    contributable.uploader?(c_utor)
  end
  
  def shared_with_networks
    networks = []
    self.policy.permissions.each do |p|
      if p.contributor_type == 'Network'
        networks << p.contributor
      end
    end
    networks
  end
end
