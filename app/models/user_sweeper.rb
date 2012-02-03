# myExperiment: app/models/user_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class UserSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe User

  def after_create(user)
    expire_listing(user.id, 'User')
    expire_sidebar_user_monitor(user.id)
  end

  def after_update(user)
    expire_listing(user.id, 'User')
    expire_sidebar_user_monitor(user.id)
    expire_all_friends_sidebar_assets(user.id)
  end

  def after_destroy(user)
    expire_listing(user.id, 'User')
    expire_sidebar_user_monitor(user.id)
  end
end
