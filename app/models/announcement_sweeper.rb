# myExperiment: app/models/announcement_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class AnnouncementSweeper < ActionController::Caching::Sweeper

  observe Announcement

  def after_create(announcement)
    expire_announcements
  end

  def after_destroy(announcement)
    expire_announcements
  end

  def after_update(announcement)
    expire_announcements
  end

  private

  def expire_announcements
    expire_fragment(:controller => 'home_cache', :action => 'announcements')
  end
end
