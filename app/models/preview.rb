# myExperiment: app/models/preview.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class Preview < ActiveRecord::Base

  PREFIX = "tmp/previews"

  acts_as_structured_data

  # :dependent => :destroy is not supported in belongs_to in rails 1.2.6
  after_destroy { |p| p.content_blob.destroy }

  def file_name(type)
    "#{PREFIX}/#{id}/#{type}"
  end

  def clear_cache
    FileUtils.rm_rf("#{PREFIX}/#{id}")
  end
end

