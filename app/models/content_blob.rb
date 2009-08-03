# myExperiment: app/models/content_blob.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContentBlob < ActiveRecord::Base
  validates_presence_of :data
end
