# myExperiment: app/models/bookmark.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Bookmark < ActiveRecord::Base
  belongs_to :bookmarkable, :polymorphic => true
  
  # NOTE: install the acts_as_taggable plugin if you 
  # want bookmarks to be tagged.
  # acts_as_taggable
  
  # NOTE: Comments belong to a user
  belongs_to :user
  
  validates_presence_of :bookmarkable
  validates_presence_of :user

  validate :check_duplicate_favourites

  # Helper class method to lookup all comments assigned
  # to all commentable types for a given user.
  def self.find_bookmarks_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  # Helper class method to look up a commentable object
  # given the commentable class name and id 
  def self.find_bookmarkable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def check_duplicate_favourites
    if Bookmark.find_by_user_id_and_bookmarkable_type_and_bookmarkable_id(user_id, bookmarkable_type, bookmarkable_id)
      errors.add_to_base("Objects cannot be favourited more than once")
    end
  end
end
