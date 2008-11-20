# myExperiment: app/models/pack_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Pack

  def after_create(pack)
    expire_sidebar_assets(pack.contributor_id) if pack.contributor_type == 'User'
    expire_listing(pack.contributor_id, pack.contributor_type) if pack.contributor_type == 'Network'
    expire_home_cache
  end

  def after_update(pack)
    expire_sidebar_assets(pack.contributor_id) if pack.contributor_type == 'User'
    expire_multiple_sidebar_favourites(pack.id, 'Pack')
    expire_listing(pack.id, 'Pack')
    expire_home_cache
  end

  def after_destroy(pack)
    expire_sidebar_assets(pack.contributor_id) if pack.contributor_type == 'User'
    expire_listing(pack.contributor_id, pack.contributor_type) if pack.contributor_type == 'Network'
    expire_listing(pack.id, 'Pack')
    expire_home_cache
  end

  private

  def expire_home_cache
    expire_home_cache_updated_items
    expire_home_cache_latest_comments
    expire_home_cache_latest_tags
  end
end
