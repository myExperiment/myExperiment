class WorkflowPort < ActiveRecord::Base

  attr_accessible :workflow, :port_type, :name

  validates_inclusion_of :port_type, :in => ["input", "output"]
  belongs_to :workflow
end
