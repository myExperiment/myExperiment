class NetworkSweeper < ActionController::Caching::Sweeper

  observe Network

  def after_create(network)
    expire_sidebar_assets(network.user_id)
  end

  def after_destroy(network)
    expire_sidebar_assets(network.user_id)
  end

  def after_update(network)
    expire_sidebar_assets(network.user_id)
  end

  private

  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end
end
