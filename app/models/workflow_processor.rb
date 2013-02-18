# myExperiment: app/models/workflow_processor.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class WorkflowProcessor < ActiveRecord::Base
  belongs_to :workflow
  has_many :semantic_annotations, :as => :subject, :dependent => :destroy
end

