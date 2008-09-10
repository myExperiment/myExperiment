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
