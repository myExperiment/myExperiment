# myExperiment: app/models/message_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class MessageSweeper < ActionController::Caching::Sweeper

  observe Message

  def after_create(message)
    expire_sidebar_user_monitor(message.from)
    expire_sidebar_user_monitor(message.to)
  end

  def after_update(message)
    expire_sidebar_user_monitor(message.from)
    expire_sidebar_user_monitor(message.to)
  end

  def after_destroy(message)
    expire_sidebar_user_monitor(message.from)
    expire_sidebar_user_monitor(message.to)
  end

  private

  def expire_sidebar_user_monitor(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_monitor', :id => user_id)
  end
end
