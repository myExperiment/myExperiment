# myExperiment: app/models/bookmark_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BookmarkSweeper < ActionController::Caching::Sweeper

  observe Bookmark

  def after_create(bookmark)
    expire_sidebar_favourites(bookmark.user_id)
  end

  def after_destroy(bookmark)
    expire_sidebar_favourites(bookmark.user_id)
  end

  private

  def expire_sidebar_favourites(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_favourites', :id => user_id)
  end
end
