# myExperiment: app/models/tag_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class TagSweeper < ActionController::Caching::Sweeper

  # observes both Tag and Tagging but currently only changes to Taggings are used to expire the 
  # cache as changes to one implies changes in the other => only one needs to be monitored
  observe Tag, Tagging

  def after_create(model)
    if model.kind_of?(Tagging)
      expire_sidebar_popular_tags
      expire_class_tags(model.taggable_type)
      expire_listing(model.taggable_id, model.taggable_type)
      expire_home_cache

      # expires the cache of all users who have used the current tag so that the relative
      # sizes of the tags in the sidebar are updated as the popularity of the tag changes
      taggings = get_taggings_to_expire(model.tag_id)
      taggings.each do |t|
        expire_sidebar_user_tags(t.user_id)
      end
    end
  end

  def after_update(model)
    if model.kind_of?(Tagging)
      expire_sidebar_popular_tags
      expire_class_tags(model.taggable_type)
      expire_listing(model.taggable_id, model.taggable_type)
      expire_home_cache

      taggings = get_taggings_to_expire(model.tag_id)
      taggings.each do |t|
        expire_sidebar_user_tags(t.user_id)
      end
    end
  end

  def after_destroy(model)
    if model.kind_of?(Tagging)
      expire_sidebar_popular_tags
      expire_class_tags(model.taggable_type)
      expire_listing(model.taggable_id, model.taggable_type)
      expire_home_cache

      taggings = get_taggings_to_expire(model.tag_id)
      taggings.each do |t|
        expire_sidebar_user_tags(t.user_id)
      end
    end
  end

  private

  # returns all tagging records which have the specified tag_id
  def get_taggings_to_expire(tag_id)
    Tagging.find(:all, :conditions => ["tag_id = ?", tag_id])
  end

  # get the 'controller' name for where the cache is stored
  def get_controller_string(taggable_type)
    case taggable_type
    when 'Workflow'
      controller = 'workflows'
    when 'Blob'
      controller = 'files'
    when 'Pack'
      controller = 'packs'
    when 'Network'
      controller = 'groups'
    else
      controller = ''
    end

    controller
  end

  def expire_sidebar_user_tags(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'user_tags', :id => user_id)
  end

  def expire_sidebar_popular_tags
    expire_fragment(:controller => 'sidebar_cache', :action => 'tags', :part => 'most_popular_tags')
  end

  # expires the 'all_tags' cache for the relevant taggable_type
  def expire_class_tags(taggable_type)
    controller = get_controller_string(taggable_type)

    expire_fragment(:controller => controller, :action => 'all_tags')
  end

  # expires the cache in /controller/listing/id.cache
  def expire_listing(taggable_id, taggable_type)
    controller = get_controller_string(taggable_type)
    controller += '_cache'

    expire_fragment(:controller => controller, :action => 'listing', :id => taggable_id)
  end

  def expire_home_cache
    expire_fragment(%r{home_cache/latest_tags/[0-9]+})
  end
end
