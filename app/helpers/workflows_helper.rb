# myExperiment: app/helpers/workflows_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowsHelper
  
  def workflow_types
    types = WorkflowTypesHandler.types_list
    types.sort! {|x,y| x.downcase <=> y.downcase}
    types << "Other"
  end
  
  def get_type_dir(workflow)
    klass = workflow.processor_class
    return (klass.nil? ? "other" : h(klass.to_s.demodulize.underscore))
  end
  
end
