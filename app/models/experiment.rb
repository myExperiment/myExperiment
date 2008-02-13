# myExperiment: app/models/experiment.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class Experiment < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  
  has_many :jobs
  
  format_attribute :description
end
