# myExperiment: app/models/job.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class Job < ActiveRecord::Base
  belongs_to :runnable, :polymorphic => true
  belongs_to :runner, :polymorphic => true
  
  belongs_to :experiment
  
  format_attribute :description
end
