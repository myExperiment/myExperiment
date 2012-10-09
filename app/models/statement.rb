# myExperiment: app/models/statements.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class Statement < ActiveRecord::Base

  belongs_to :research_object

  validates_presence_of :subject_text
  validates_presence_of :predicate_text
  validates_presence_of :objekt_text

end

