# myExperiment: app/models/group_announcement_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class GroupAnnouncementSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe GroupAnnouncement

  # for "create","destroy" and "update" need to expire all places, where
  # cached content for group announcements is located:
  # - listing of groups, as it contains the number of group announcements in it and the link/title of the last announcement
  #
  # However content in
  # - listing of group announcements;
  # - group announcements box on group's page
  # is user-specific: i.e. either public or private&public
  # group announcements are shown to the current user
  def after_create(group_announcement)
    expire_group_announcement(group_announcement)
  end


  def after_destroy(group_announcement)
    expire_group_announcement(group_announcement)
  end
 
 
  def after_update(group_announcement)
    expire_group_announcement(group_announcement)
  end
  
  
  private
  
  def expire_group_announcement(group_announcement)
    expire_listing(group_announcement.network.id, 'Network')
  end

end
