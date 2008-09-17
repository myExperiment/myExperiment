# myExperiment: app/models/bookmark_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BookmarkSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Bookmark

  def after_create(bookmark)
    expire_sidebar_favourites(bookmark.user_id)
  end

  def after_destroy(bookmark)
    expire_sidebar_favourites(bookmark.user_id)
  end
end
