# myExperiment: app/models/content_blob.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'digest/md5'
require 'digest/sha1'

class ContentBlob < ActiveRecord::Base
  validates_presence_of :data

  before_save do |blob|
    blob.update_checksums
  end

  def update_checksums
    self.md5  = Digest::MD5.hexdigest(data)
    self.sha1 = Digest::SHA1.hexdigest(data)
  end

end
