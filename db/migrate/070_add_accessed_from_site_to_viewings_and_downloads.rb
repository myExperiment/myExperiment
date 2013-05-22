class AddAccessedFromSiteToViewingsAndDownloads < ActiveRecord::Migration
  
  # a boolean field ("accessed_from_site") is added to "viewings" and "downloads" tables
  # to record if viewing/download was initiated from myExperiment website - that is
  # non-direct link was used and, therefore, 'referer' in the http header would contain
  # "myexperiment" as a part of the link
  
  def self.up
    add_column :viewings, :accessed_from_site, :boolean, :default => false
#   add_column :downloads, :accessed_from_site, :boolean, :default => false
  end

  def self.down
    remove_column :viewings, :accessed_from_site
#   remove_column :downloads, :accessed_from_site
  end
end
