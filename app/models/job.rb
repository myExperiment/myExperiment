# myExperiment: app/models/job.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class Job < ActiveRecord::Base
  
  belongs_to :runnable, :polymorphic => true
  validates_presence_of :runnable
  
  belongs_to :runner, :polymorphic => true
  validates_presence_of :runner
  
  belongs_to :experiment
  validates_presence_of :experiment
  
  format_attribute :description
  
  validates_presence_of :title
  
  def authorized?(action_name, c_utor=nil)
    # Use authorization logic from parent Experiment
    return self.experiment.authorized?(action_name, c_utor)
  end
  
  def submit_and_run(inputs)
    
  end
end
