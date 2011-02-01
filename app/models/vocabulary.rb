# myExperiment: app/models/vocabulary.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class Vocabulary < ActiveRecord::Base

  acts_as_structured_data

  belongs_to :user

  validates_presence_of :title
  validates_presence_of :prefix

  validates_uniqueness_of :prefix

  format_attribute :description
end

