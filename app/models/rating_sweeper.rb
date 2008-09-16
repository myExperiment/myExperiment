# myExperiment: app/models/rating_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class RatingSweeper < ActionController::Caching::Sweeper

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
  def expire_listing(rateable_id, rateable_type)
    controller = get_controller_string(rateable_type)
    controller += '_cache'

    expire_fragment(:controller => controller, :action => 'listing', :id => rateable_id)
  end
end
