# myExperiment: app/models/comment.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  
  # NOTE: install the acts_as_votable plugin if you 
  # want user to vote on the quality of comments.
  #acts_as_voteable
  
  # NOTE: Comments belong to a user
  belongs_to :user
  
  acts_as_solr :fields => [ :comment ] if SOLR_ENABLE
  
  acts_as_simile_timeline_event(
    :fields => {
      :start       => :created_at,
      :title       => :simile_title,
      :description => :simile_description,
    }
  )
  
  validates_presence_of :comment
  validates_presence_of :commentable_type
  validates_presence_of :commentable_id

  def simile_title
    "Comment by: #{self.user.name}"
  end
  
  def simile_description
    "#{self.comment}"
  end
  
  # returns the 'last created' Comments
  # the maximum number of results is set by #limit#
  def self.latest(limit=10)
    self.find(:all,
              :order => "created_at DESC",
              :limit => limit)
  end

  # Helper class method to lookup all comments assigned
  # to all commentable types for a given user.
  def self.find_comments_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  # Helper class method to look up all comments for 
  # commentable class name and commentable id.
  def self.find_comments_for_commentable(commentable_str, commentable_id)
    find(:all,
      :conditions => ["commentable_type = ? and commentable_id = ?", commentable_str, commentable_id],
      :order => "created_at DESC"
    )
  end

  # Helper class method to look up a commentable object
  # given the commentable class name and id 
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end
end
