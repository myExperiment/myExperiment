# myExperiment: app/models/friendship_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class FriendshipSweeper < ActionController::Caching::Sweeper

  include CachingHelper
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
end
