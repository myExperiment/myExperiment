# myExperiment: app/models/algorithm_instance.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class AlgorithmInstance < ActiveRecord::Base
  belongs_to :algorithm
  belongs_to :app
end

