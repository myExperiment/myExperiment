# myExperiment: app/models/pack_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackSweeper < ActionController::Caching::Sweeper

  observe Pack

  def after_create(pack)
    expire_sidebar_assets(pack.contributor_id) if pack.contributor_type == 'User'
    expire_listing(pack.contributor_id, 'groups_cache') if pack.contributor_type == 'Network'
    expire_home_cache
  end

  def after_update(pack)
    expire_listing(pack.id, 'packs_cache')
    expire_home_cache
  end

  def after_destroy(pack)
    expire_sidebar_assets(pack.contributor_id) if pack.contributor_type == 'User'
    expire_listing(pack.contributor_id, 'groups_cache') if pack.contributor_type == 'Network'
    expire_listing(pack.id, 'packs_cache')
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
