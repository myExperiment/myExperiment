# myExperiment: app/models/network_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class NetworkSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Network

  def after_create(network)
    expire_sidebar_assets(network.user_id)
    expire_home_cache
  end

  def after_update(network)
    expire_sidebar_assets(network.user_id)
    expire_listing(network.id, 'Network')
    expire_home_cache
  end

  def after_destroy(network)
    expire_sidebar_assets(network.user_id)
    expire_listing(network.id, 'Network')
    expire_home_cache
  end

  private

  def expire_home_cache
    expire_home_cache_latest_comments
    expire_home_cache_latest_tags
    expire_home_cache_latest_groups
  end
end
