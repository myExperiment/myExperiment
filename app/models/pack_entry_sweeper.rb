# myExperiment: app/models/pack_entry_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackEntrySweeper < ActionController::Caching::Sweeper

  observe PackContributableEntry, PackRemoteEntry

  def after_create(model)
    expire_listing(model.pack_id)
  end

  def after_update(model)
    expire_listing(model.pack_id)
  end

  def after_destroy(model)
    expire_listing(model.pack_id)
  end

  private

  # expires the cache in /controller/listing/id.cache
  def expire_listing(pack_id)
    expire_fragment(:controller => 'packs_cache', :action => 'listing', :id => pack_id)
  end
end
