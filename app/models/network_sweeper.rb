# myExperiment: app/models/network_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class NetworkSweeper < ActionController::Caching::Sweeper

  observe Network

  def after_create(network)
    expire_sidebar_assets(network.user_id)
    expire_home_cache
  end

  def after_update(network)
    expire_sidebar_assets(network.user_id)
    expire_listing(network.id)
    expire_home_cache
  end

  def after_destroy(network)
    expire_sidebar_assets(network.user_id)
    expire_listing(network.id)
    expire_home_cache
  end

  private

  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end

  def expire_listing(network_id)
    expire_fragment(:controller => 'groups_cache', :action => 'listing', :id => network_id)
  end

  def expire_home_cache
    expire_fragment(%r{home_cache/latest_comments/[0-9]+})
    expire_fragment(%r{home_cache/latest_tags/[0-9]+})
    expire_fragment(%r{home_cache/latest_groups/[0-9]+})
  end
end
