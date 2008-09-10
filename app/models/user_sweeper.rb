# myExperiment: app/models/user_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class UserSweeper < ActionController::Caching::Sweeper

  observe User

  def after_create(user)
    expire_sidebar_user_monitor(user.id)
  end

  def after_update(user)
    expire_sidebar_user_monitor(user.id)
  end

  def after_destroy(user)
    expire_sidebar_user_monitor(user.id)
  end

  private

  def expire_sidebar_user_monitor(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_monitor', :id => user_id)
  end
end
