# myExperiment: app/models/rating_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class RatingSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Rating

  def after_create(rating)
    expire_listing(rating.rateable_id, rating.rateable_type)
  end

  def after_update(rating)
    expire_listing(rating.rateable_id, rating.rateable_type)
  end

  def after_destroy(rating)
    expire_listing(rating.rateable_id, rating.rateable_type)
  end
end
