# myExperiment: app/models/ontology.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class Ontology < ActiveRecord::Base

  acts_as_structured_data

  format_attribute(:description)

  validates_presence_of(:uri, :title, :prefix)

end

