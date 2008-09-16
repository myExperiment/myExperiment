# myExperiment: app/models/comment_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CommentSweeper < ActionController::Caching::Sweeper

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

  # get the 'controller' name for where the cache is stored
  def get_controller_string(commentable_type)
    case commentable_type
    when 'Workflow'
      controller = 'workflows'
    when 'Blob'
      controller = 'files'
    when 'Pack'
      controller = 'packs'
    when 'Network'
      controller = 'groups'
    else
      controller = ''
    end

    controller
  end

  # expires the cache in /controller/listing/id.cache
  def expire_listing(commentable_id, commentable_type)
    controller = get_controller_string(commentable_type)
    controller += '_cache'

    expire_fragment(:controller => controller, :action => 'listing', :id => commentable_id)
  end

  def expire_home_cache
    expire_fragment(%r{home_cache/latest_comments/[0-9]+})
  end
end
