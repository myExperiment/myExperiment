# myExperiment: app/models/blob_sweeper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlobSweeper < ActionController::Caching::Sweeper

  observe Blob

  def after_create(blob)
    expire_sidebar_assets(blob.contributor_id) if blob.contributor_type == 'User'
  end

  def after_destroy(blob)
    expire_sidebar_assets(blob.contributor_id) if blob.contributor_type == 'User'
  end

  private

  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end
end
