# myExperiment: app/models/workflow_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class WorkflowSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Workflow

  def after_create(workflow)
    expire_sidebar_assets(workflow.contributor_id) if workflow.contributor_type == 'User'
    expire_listing(workflow.contributor_id, workflow.contributor_type) if workflow.contributor_type == 'Network'
    expire_home_cache
  end

  def after_update(workflow)
    expire_listing(workflow.id, 'Workflow')
    expire_home_cache
  end

  def after_destroy(workflow)
    expire_sidebar_assets(workflow.contributor_id) if workflow.contributor_type == 'User'
    expire_listing(workflow.contributor_id, workflow.contributor_type) if workflow.contributor_type == 'Network'
    expire_listing(workflow.id, 'Workflow')
    expire_home_cache
  end

  private

  def expire_home_cache
    expire_home_cache_updated_items
    expire_home_cache_latest_reviews
    expire_home_cache_latest_comments
    expire_home_cache_latest_tags
  end
end
