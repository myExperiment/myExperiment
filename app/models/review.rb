# myExperiment: app/models/review.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Review < ActiveRecord::Base
  belongs_to :reviewable, :polymorphic => true
  
  #acts_as_voteable
  
  belongs_to :user
  
  before_create :check_multiple
  
  acts_as_solr :fields => [ :title, :review ] if SOLR_ENABLE
  
  # returns the 'last created' Reviews
  # the maximum number of results is set by #limit#
  def self.latest(limit=10)
    self.find(:all,
              :order => "created_at DESC",
              :limit => limit)
  end

  # Helper class method to lookup all reviews assigned
  # to all reviewable types for a given user.
  def self.find_reviews_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  # Helper class method to look up all reviews for 
  # reviewable class name and reviewable id.
  def self.find_reviews_for_reviewable(reviewable_str, reviewable_id)
    find(:all,
      :conditions => ["reviewable_type = ? and reviewable_id = ?", reviewable_str, reviewable_id],
      :order => "created_at DESC"
    )
  end

  # Helper class method to look up a reviewable object
  # given the reviewable class name and id 
  def self.find_reviewable(reviewable_str, reviewable_id)
    reviewable_str.constantize.find(reviewable_id)
  end
  
  def associated_rating
    Rating.find(:first, :conditions => ["user_id = ? AND rateable_type = ? AND rateable_id = ?", self.user_id, self.reviewable_type, self.reviewable_id])
  end
  
  def allow_edit?(user)
    return false unless user
    return user.id == self.user_id 
  end
  
protected
  
  def check_multiple
    if Review.find(:first, :conditions => ["user_id = ? AND reviewable_type = ? AND reviewable_id = ?", self.user_id, self.reviewable_type, self.reviewable_id])
      errors.add_to_base("You have already made a Review for this item")
      return false
    else
      return true
    end
  end
  
end
