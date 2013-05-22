# myExperiment: app/models/content_blob.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require 'digest/md5'
require 'digest/sha1'

class ContentBlob < ActiveRecord::Base

  before_save :update_metadata

  # validates_presence_of uses a function that assumes UTF-8 encoding and thus
  # has issues with other encodings.  The following validation provides similar
  # functionality to validates_presence_of on the content blob data.

  validate do |record|
    if record.data.nil? || record.data.length == 0
      record.errors.add(:data, 'cannot be empty.')
    end
  end

  def update_metadata

    self.md5  = Digest::MD5.hexdigest(data)
    self.sha1 = Digest::SHA1.hexdigest(data)

    case self.data
    when StringIO
      self.size = self.data.size
    when String
      self.size = self.data.bytesize
    end
  end
end
