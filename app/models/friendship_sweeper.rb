# myExperiment: app/models/friendship_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class FriendshipSweeper < ActionController::Caching::Sweeper

  observe Friendship

  def after_create(friendship)
    expire_sidebar_assets(friendship.user_id)
    expire_sidebar_assets(friendship.friend_id)

    expire_sidebar_user_monitor(friendship.user_id)
    expire_sidebar_user_monitor(friendship.friend_id)
  end

  def after_update(friendship)
    expire_sidebar_assets(friendship.user_id)
    expire_sidebar_assets(friendship.friend_id)

    expire_sidebar_user_monitor(friendship.user_id)
    expire_sidebar_user_monitor(friendship.friend_id)
  end

  def after_destroy(friendship)
    expire_sidebar_assets(friendship.user_id)
    expire_sidebar_assets(friendship.friend_id)

    expire_sidebar_user_monitor(friendship.user_id)
    expire_sidebar_user_monitor(friendship.friend_id)
  end

  private

  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end

  def expire_sidebar_user_monitor(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_monitor', :id => user_id)
  end
end
