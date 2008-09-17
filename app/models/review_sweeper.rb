# myExperiment: app/models/review_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ReviewSweeper < ActionController::Caching::Sweeper

  include CachingHelper
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

  def expire_home_cache
    expire_home_cache_latest_reviews
  end
end
