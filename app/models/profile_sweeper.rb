# myExperiment: app/models/profile_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ProfileSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Profile

  def after_create(profile)
    expire_listing(profile.user_id, 'User')
    expire_sidebar_user_monitor(profile.user_id)
  end

  def after_update(profile)
    expire_listing(profile.user_id, 'User')
    expire_sidebar_user_monitor(profile.user_id)
  end

  def after_destroy(profile)
    expire_listing(profile.user_id, 'User')
    expire_sidebar_user_monitor(profile.user_id)
  end
end
