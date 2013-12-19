# myExperiment: lib/has_research_object.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class ActiveRecord::Base

  def self.has_research_object
    has_one :research_object, :as => 'context', :dependent => :destroy
  end

  def self.has_resource
    has_one :resource, :as => :context, :dependent => :destroy
  end

  def find_resource_by_path(path)
    research_object.resources.find_by_path(relative_uri(path, research_object.uri))
  end

  def find_resource_by_ore_path(path)
    research_object.find_using_path(relative_uri(path, research_object.uri))
  end

end
