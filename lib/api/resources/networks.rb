# myExperiment: lib/api/resources/networks.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def group_count(opts)

  root = LibXML::XML::Node.new('group-count')
  root << Network.count.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end
