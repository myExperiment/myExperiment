# myExperiment: app/models/profile_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ProfileSweeper < ActionController::Caching::Sweeper

  observe Profile

  def after_create(profile)
    expire_sidebar_user_monitor(profile.user_id)
  end

  def after_update(profile)
    expire_sidebar_user_monitor(profile.user_id)
  end

  def after_destroy(profile)
    expire_sidebar_user_monitor(profile.user_id)
  end

  private

  def expire_sidebar_user_monitor(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_monitor', :id => user_id)
  end
end
