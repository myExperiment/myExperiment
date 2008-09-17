# myExperiment: app/models/citation_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CitationSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Citation

  def after_create(citation)
    expire_listing(citation.workflow_id, 'Workflow')
  end

  def after_update(citation)
    expire_listing(citation.workflow_id, 'Workflow')
  end

  def after_destroy(citation)
    expire_listing(citation.workflow_id, 'Workflow')
  end
end
