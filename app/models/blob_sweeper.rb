# myExperiment: app/models/blob_sweeper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlobSweeper < ActionController::Caching::Sweeper

  observe Blob

  def after_create(blob)
    expire_sidebar_assets(blob.contributor_id) if blob.contributor_type == 'User'
    expire_listing(blob.contributor_id, 'groups_cache') if blob.contributor_type == 'Network'
    expire_home_cache
  end

  def after_update(blob)
    expire_listing(blob.id, 'files_cache')
    expire_home_cache
  end

  def after_destroy(blob)
    expire_sidebar_assets(blob.contributor_id) if blob.contributor_type == 'User'
    expire_listing(blob.contributor_id, 'groups_cache') if blob.contributor_type == 'Network'
    expire_listing(blob.id, 'files_cache')
    expire_home_cache
  end

  private

  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end

  def expire_listing(id, controller)
    expire_fragment(:controller => controller, :action => 'listing', :id => id)
  end

  def expire_home_cache
    expire_fragment(%r{home_cache/updated_items/[0-9]+})
    expire_fragment(%r{home_cache/latest_comments/[0-9]+})
    expire_fragment(%r{home_cache/latest_tags/[0-9]+})
  end
end
