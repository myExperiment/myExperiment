# myExperiment: app/models/download_viewing_sweeper.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class DownloadViewingSweeper < ActionController::Caching::Sweeper

  include CachingHelper
  observe Viewing, Download

  def after_create(model)
    contribution = Contribution.find(:first, :conditions => "id=#{model.contribution_id}")
    expire_listing(contribution.contributable_id, contribution.contributable_type)
  end
end
