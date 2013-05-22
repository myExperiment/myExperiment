# myExperiment: app/models/content_blob.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'digest/md5'
require 'digest/sha1'

class ContentBlob < ActiveRecord::Base

  validate do |record|
    if record.data.nil? || record.data.length == 0
      record.errors.add(:data, 'cannot be empty.')
    end
  end

  before_save do |blob|
    blob.update_checksums
  end

  def update_checksums
    self.md5  = Digest::MD5.hexdigest(data)
    self.sha1 = Digest::SHA1.hexdigest(data)
  end

end
