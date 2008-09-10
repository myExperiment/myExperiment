class PackSweeper < ActionController::Caching::Sweeper

  observe Pack

  def after_create(pack)
    expire_sidebar_assets(pack.contributor_id) if pack.contributor_type == 'User'
  end

  def after_destroy(pack)
    expire_sidebar_assets(pack.contributor_id) if pack.contributor_type == 'User'
  end

  private

  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end
end
