class WorkflowSweeper < ActionController::Caching::Sweeper

  observe Workflow

  def after_create(workflow)
    expire_sidebar_assets(workflow.contributor_id) if workflow.contributor_type == 'User'
  end

  def after_destroy(workflow)
    expire_sidebar_assets(workflow.contributor_id) if workflow.contributor_type == 'User'
  end

  private

  def expire_sidebar_assets(user_id)
    expire_fragment(:controller => 'sidebar_cache', :action => 'asset_manager', :id => user_id)
  end
end
