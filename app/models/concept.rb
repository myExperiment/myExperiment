# myExperiment: app/models/concept.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class Concept < ActiveRecord::Base

  acts_as_structured_data

  format_attribute :description

  def preferred_label
    preferred_labels.first
  end

end

