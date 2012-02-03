# myExperiment: app/models/permission_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PermissionSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Permission

  def after_create(permission)
    expire_listing(permission.contributor_id, permission.contributor_type) if permission.contributor_type == 'Network'
  end

  def after_update(permission)
    expire_listing(permission.contributor_id, permission.contributor_type) if permission.contributor_type == 'Network'
  end

  def after_destroy(permission)
    expire_listing(permission.contributor_id, permission.contributor_type) if permission.contributor_type == 'Network'
  end
end
