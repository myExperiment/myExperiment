# myExperiment: app/models/map_sweeper.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class MapSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Map

  def after_create(map)
    expire_sidebar_assets(map.contributor_id) if map.contributor_type == 'User'
    expire_listing(map.contributor_id, map.contributor_type) if map.contributor_type == 'Network'
    expire_home_cache
  end

  def after_update(map)
    expire_sidebar_assets(map.contributor_id) if map.contributor_type == 'User'
    expire_multiple_sidebar_favourites(map.id, 'Map')
    expire_listing(map.id, 'Map')
    expire_home_cache
  end

  def after_destroy(map)
    expire_sidebar_assets(map.contributor_id) if map.contributor_type == 'User'
    expire_listing(map.contributor_id, map.contributor_type) if map.contributor_type == 'Network'
    expire_listing(map.id, 'Map')
    expire_home_cache
  end

  private

  def expire_home_cache
    expire_home_cache_updated_items
    expire_home_cache_latest_comments
    expire_home_cache_latest_tags
  end
end

