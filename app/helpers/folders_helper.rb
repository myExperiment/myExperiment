# myExperiment: app/helpers/folders_helper.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.
module FoldersHelper
  # TODO: Move to config
  BASE_URI = "http://sandbox.wf4ever-project.org/rodl/ROs/"
  API_KEY = "32801fc0-1df1-4e34-b"
  
  def make_research_object(ro_uri) 
    session = ROSRS::Session.new(BASE_URI, API_KEY)
    ROSRS::ResearchObject.new(session, ro_uri)    
  end
  
  def make_tree_view_structure(ro)
     {:label => ro.root_folder.name,
      :labelStyle => "root_folder",
      :uri => ro.root_folder.uri}
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