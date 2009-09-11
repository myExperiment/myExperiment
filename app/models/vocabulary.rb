# myExperiment: app/models/vocabulary.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class Vocabulary < ActiveRecord::Base

  belongs_to :user

  has_many :tags, :dependent => :destroy

  validates_presence_of :title

  format_attribute :description
end

