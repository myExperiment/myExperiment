# myExperiment: lib/api/resources/users.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def user_count(opts)

  users = User.find(:all).select do |user| user.activated? end

  root = LibXML::XML::Node.new('user-count')
  root << users.length.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end
