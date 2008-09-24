# myExperiment: app/models/blob_sweeper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlobSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Blob

  def after_create(blob)
    expire_sidebar_assets(blob.contributor_id) if blob.contributor_type == 'User'
    expire_listing(blob.contributor_id, blob.contributor_type) if blob.contributor_type == 'Network'
    expire_home_cache
  end

  def after_update(blob)
    expire_sidebar_assets(blob.contributor_id) if blob.contributor_type == 'User'
    expire_multiple_sidebar_favourites(blob.id, 'Blob')
    expire_listing(blob.id, 'Blob')
    expire_home_cache
  end

  def after_destroy(blob)
    expire_sidebar_assets(blob.contributor_id) if blob.contributor_type == 'User'
    expire_listing(blob.contributor_id, blob.contributor_type) if blob.contributor_type == 'Network'
    expire_listing(blob.id, 'Blob')
    expire_home_cache
  end

  private

  def expire_home_cache
    expire_home_cache_updated_items
    expire_home_cache_latest_comments
    expire_home_cache_latest_tags
  end
end
