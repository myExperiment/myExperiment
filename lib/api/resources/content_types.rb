# myExperiment: lib/api/resources/content_types.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def content_type_count(opts)

  root = LibXML::XML::Node.new('type-count')
  root << ContentType.count.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end
