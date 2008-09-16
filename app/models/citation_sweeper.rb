# myExperiment: app/models/citation_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CitationSweeper < ActionController::Caching::Sweeper

  observe Citation

  def after_create(citation)
    expire_listing(citation.workflow_id)
  end

  def after_update(citation)
    expire_listing(citation.workflow_id)
  end

  def after_destroy(citation)
    expire_listing(citation.workflow_id)
  end

  private

  # expires the cache in /controller/listing/id.cache
  def expire_listing(workflow_id)
    expire_fragment(:controller => 'workflows_cache', :action => 'listing', :id => workflow_id)
  end
end
