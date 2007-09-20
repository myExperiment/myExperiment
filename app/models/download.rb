class Download < ActiveRecord::Base
  belongs_to :contribution,
             :counter_cache => true
             
  belongs_to :user,
             :counter_cache => true
             
  validates_presence_of :contribution
  
  # returns the 'most recent' Downloads #after# a given time
  # the maximum number of results is set by #limit#
  def self.most_recent(after=(Time.now - 3.hours), limit=10)
    self.find(:all, :conditions => ["created_at > ?", after], :order => "created_at DESC", :limit => limit)
  end
  
  # returns an array of Downloads by the user specified with #user_id#
  # the array contains exactly one record for each viewed Contribution (with the extra variable #count#)
  # the maximum number of results is set by #limit#
  def self.most_by_user(user_id, limit=10)
    self.find(:all, 
              :select => "contribution_id, user_id, count(contribution_id) AS count",
              :group => "contribution_id", 
              :conditions => ["user_id = ?", user_id], 
              :order => "count DESC",
              :limit => limit)
  end
end
