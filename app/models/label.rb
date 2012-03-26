# myExperiment: app/models/label.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class Label < ActiveRecord::Base
  belongs_to :vocabulary
  belongs_to :concept
end

