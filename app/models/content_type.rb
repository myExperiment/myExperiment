# myExperiment: app/models/content_type.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContentType < ActiveRecord::Base
  format_attribute :description

  belongs_to :user

  validates_presence_of :title
  validates_uniqueness_of :title
end
