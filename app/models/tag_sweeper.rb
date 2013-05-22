# myExperiment: app/models/tag_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class TagSweeper < ActionController::Caching::Sweeper

  include CachingHelper

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

  def expire_home_cache
    expire_home_cache_latest_tags
  end
end
