# myExperiment: app/models/review_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ReviewSweeper < ActionController::Caching::Sweeper

  observe Review

  def after_create(review)
    expire_listing(review.reviewable_id, review.reviewable_type)
    expire_home_cache
  end

  def after_update(review)
    expire_listing(review.reviewable_id, review.reviewable_type)
    expire_home_cache
  end

  def after_destroy(review)
    expire_listing(review.reviewable_id, review.reviewable_type)
    expire_home_cache
  end

  private

  # get the 'controller' name for where the cache is stored
  def get_controller_string(rateable_type)
    case rateable_type
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

  # expires the cache in /controller/listing/id.cache
  def expire_listing(reviewable_id, reviewable_type)
    controller = get_controller_string(rateable_type)
    controller += '_cache'

    expire_fragment(:controller => controller, :action => 'listing', :id => reviewable_id)
  end

  def expire_home_cache
    expire_fragment(%r{home_cache/latest_reviews/[0-9]+})
  end
end
