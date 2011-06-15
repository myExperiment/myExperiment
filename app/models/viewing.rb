class Viewing < ActiveRecord::Base

  belongs_to :contribution
  belongs_to :user
             
  validates_presence_of :contribution
  
  after_save { |viewing|
    Contribution.increment_counter(:viewings_count,      viewing.contribution.id)
    Contribution.increment_counter(:site_viewings_count, viewing.contribution.id) if viewing.accessed_from_site

    User.increment_counter(:viewings_count, viewing.user.id) if viewing.user
  }

  # returns the 'most recent' Viewings #after# a given time
  # the maximum number of results is set by #limit#
  def self.most_recent(after=(Time.now - 3.hours), limit=10)
    self.find(:all, 
              :conditions => ["created_at > ?", after], 
              :order => "created_at DESC", 
              :limit => limit)
  end
  
  # returns an array of Viewings by the user specified with #user_id#
  # the array contains exactly one record for each viewed Contribution (with the extra variable #count#)
  # the maximum number of results is set by #limit#
  def self.most_by_user(user_id, limit=10)
    self.find(:all, 
              :select => "contribution_id, count(user_id) AS count",
              :group => "contribution_id", 
              :conditions => ["user_id = ?", user_id], 
              :order => "count DESC",
              :limit => limit)
  end

  # returns an array of Viewings for the contribution specified with #contribution_id#
  # the array contains exactly one record for each User (with the extra variable #count#)
  # the maximum number of results is set by #limit#
  def self.most_by_contribution(contribution_id, limit=10)
    self.find(:all, 
              :select => "user_id, count(contribution_id) AS count",
              :group => "user_id", 
              :conditions => ["contribution_id = ?", contribution_id], 
              :order => "count DESC",
              :limit => limit)
  end
  
  # returns the number of member viewings from myExperiment website 
  # for the contribution given by ID - i.e. viewings from myExperiment
  # website done by logged in users
  def self.member_site_viewings_count_for_contribution(contribution_id)
    self.count(:all, :conditions => ["contribution_id = ? AND accessed_from_site = ? AND user_id IS NOT NULL", contribution_id, true])
  end
  
  # returns the number of anonymous viewings from the website for the contribution
  def self.anonymous_site_viewings_count_for_contribution(contribution_id)
    self.count(:all, :conditions => ["contribution_id = ? AND accessed_from_site = ? AND user_ID IS NULL", contribution_id, true])
  end
  
  # returns total number of downloads for the contribution from the website
  def self.total_site_viewings_count_for_contribution(contribution_id)
    self.count(:all, :conditions => ["contribution_id = ? AND accessed_from_site = ?", contribution_id, true])
  end
end
