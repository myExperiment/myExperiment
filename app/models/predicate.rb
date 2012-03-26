# myExperiment: app/models/predicate.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class Predicate < ActiveRecord::Base

  belongs_to :ontology

  format_attribute(:description)

  validates_presence_of(:title)
  validates_presence_of(:ontology)

  def label
    title
  end
end

