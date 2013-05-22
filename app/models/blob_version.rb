# myExperiment: app/models/blob_versions.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlobVersion < ActiveRecord::Base

  is_version_of :blob

  format_attribute :body

  belongs_to :content_blob, :dependent => :destroy
  belongs_to :content_type

  validates_presence_of :content_blob
  validates_presence_of :content_type
  validates_presence_of :title

  def suggestions
    {
      :revision_comments => version > 1 && (revision_comments.nil? || revision_comments.empty?),
      :description => body.nil? || body.empty?
    }
  end

  def suggestions?
    suggestions.select do |k, v| v end.length > 0
  end
end

