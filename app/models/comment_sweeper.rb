# myExperiment: app/models/comment_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CommentSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Comment

  def after_create(comment)
    expire_listing(comment.commentable_id, comment.commentable_type)
    expire_home_cache
  end

  def after_update(comment)
    expire_listing(comment.commentable_id, comment.commentable_type)
    expire_home_cache
  end

  def after_destroy(comment)
    expire_listing(comment.commentable_id, comment.commentable_type)
    expire_home_cache
  end

  private

  def expire_home_cache
    expire_home_cache_latest_comments
  end
end
