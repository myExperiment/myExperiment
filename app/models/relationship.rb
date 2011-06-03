# myExperiment: app/models/relationship.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class Relationship < ActiveRecord::Base

  acts_as_structured_data

  validates_uniqueness_of :predicate_id, :scope => [:subject_id, :objekt_id]

end

