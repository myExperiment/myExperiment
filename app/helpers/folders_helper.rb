# myExperiment: app/helpers/folders_helper.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.
module FoldersHelper
  
  def make_research_object(ro_uri) 
    session = ROSRS::Session.new(Conf.rodl_base_uri, Conf.rodl_bearer_token)
    ROSRS::ResearchObject.new(session, ro_uri)    
  end
  
  def make_tree_view_structure(ro)
    if (ro.root_folder)
      { :label => ro.root_folder.name,
        :labelStyle => "root_folder",
        :uri => ro.root_folder.uri }
    end
  end
  
  def make_resources(ro)
    resources = {}
    (ro.resources + ro.folders).each do |res|
      type = 'folder'
      leaf = false
      unless res.is_a?(ROSRS::Folder)
        type = 'resource'
        leaf = true
      end
      resources[res.uri] = {:labelStyle => type, :uri => res.uri, :isLeaf => leaf}
    end 
    resources
  end
  
end
