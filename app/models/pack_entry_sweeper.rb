# myExperiment: app/models/pack_entry_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackEntrySweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe PackContributableEntry, PackRemoteEntry

  def after_create(model)
    expire_listing(model.pack_id, 'Pack')
  end

  def after_update(model)
    expire_listing(model.pack_id, 'Pack')
  end

  def after_destroy(model)
    expire_listing(model.pack_id, 'Pack')
  end
end
