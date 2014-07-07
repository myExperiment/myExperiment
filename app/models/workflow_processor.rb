# myExperiment: app/models/workflow_processor.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class WorkflowProcessor < ActiveRecord::Base

  attr_accessible :workflow, :name, :wsdl, :wsdl_operation

  belongs_to :workflow
end

