# myExperiment: app/models/predicate.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class Predicate < ActiveRecord::Base

  acts_as_structured_data

  format_attribute(:description)

  validates_presence_of(:title)
  validates_presence_of(:ontology)

end

