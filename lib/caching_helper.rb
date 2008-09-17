# myExperiment: lib/caching_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module CachingHelper
  
  # Methods to expire caches for the home page
  
  def expire_home_cache_updated_items
    expire_fragment(%r{home_cache/updated_items/[0-9]+})
  end
  
  def expire_home_cache_latest_reviews
    expire_fragment(%r{home_cache/latest_reviews/[0-9]+})
  end
  
  def expire_home_cache_latest_comments
    expire_fragment(%r{home_cache/latest_comments/[0-9]+})
  end
  
  def expire_home_cache_latest_tags
    expire_fragment(%r{home_cache/latest_tags/[0-9]+})
  end
  
  def expire_home_cache_latest_groups
    expire_fragment(%r{home_cache/latest_groups/[0-9]+})
  end
  
  # Methods to expire caches for the sidebar
  
  def expire_sidebar_user_monitor(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_monitor', :id => user_id)
  end
  
  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end
  
  def expire_sidebar_favourites(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_favourites', :id => user_id)
  end
  
  def expire_sidebar_user_tags(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_tags', :id => user_id)
  end
  
  def expire_sidebar_popular_tags
    expire_fragment(:controller => 'sidebar_cache', :action => 'tags', :part => 'most_popular_tags')
  end
  
  # expires the cache in /controller/listing/id.cache
  # takes a numerical id and a String klass (eg Workflow or Network)
  def expire_listing(id, klass)
    controller = get_controller_string(klass)
    controller += '_cache'

    expire_fragment(:controller => controller, :action => 'listing', :id => id)
  end
  
  # expires the 'all_tags' cache for the given controller
  def expire_class_tags(klass)
    controller = get_controller_string(klass)

    expire_fragment(:controller => controller, :action => 'all_tags')
  end
  
  # get the 'controller' name for where the cache is stored
  def get_controller_string(klass)
    case klass
    when 'Workflow'
      controller = 'workflows'
    when 'Blob'
      controller = 'files'
    when 'Pack'
      controller = 'packs'
    when 'Network'
      controller = 'groups'
    when 'User'
      controller = 'users'
    else
      controller = ''
    end

    controller
  end
end
