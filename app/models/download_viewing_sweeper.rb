# myExperiment: app/models/download_viewing_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class DownloadViewingSweeper < ActionController::Caching::Sweeper

  observe Viewing, Download

  def after_create(model)
    contribution = Contribution.find(:first, :conditions => "id=#{model.contribution_id}")
    expire_listing(contribution.contributable_id, contribution.contributable_type)
  end

  private

  # get the 'controller' name for where the cache is stored
  def get_controller_string(contributable_type)
    case contributable_type
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
  def expire_listing(contributable_id, contributable_type)
    controller = get_controller_string(contributable_type)
    controller += '_cache'

    expire_fragment(:controller => controller, :action => 'listing', :id => contributable_id)
  end
end
