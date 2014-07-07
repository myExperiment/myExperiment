# myExperiment: app/models/content_blob.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require 'digest/md5'
require 'digest/sha1'

class ContentBlob < ActiveRecord::Base

  attr_accessible :data

  before_save :update_metadata

  validate do |record|
    if record.data.nil?
      record.errors.add(:data, 'cannot be undefined.')
    end
  end

  def update_metadata
    calc_sha1
    calc_md5
    calc_size
  end

  def calc_sha1
    self.sha1 = Digest::SHA1.hexdigest(data)
  end

  def calc_md5
    self.md5  = Digest::MD5.hexdigest(data)
  end

  def calc_size
    case self.data
    when StringIO
      self.size = self.data.size
    when String
      self.size = self.data.bytesize
    end
  end
end
