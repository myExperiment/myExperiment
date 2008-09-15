# myExperiment: app/helpers/workflows_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module WorkflowsHelper
  
  def workflow_types
    types = WorkflowTypesHandler.types_list
    types.sort! {|x,y| x <=> y}
    types << "Other"
  end
  
  def get_type_dir(workflow)
    klass = WorkflowTypesHandler.processor_class_for_content_type(workflow.content_type)
    
    return "other" if klass.nil?
    
    return h(klass.to_s.demodulize.underscore)
  end
  
  def get_main_download_data_format(workflow)
    klass = WorkflowTypesHandler.processor_class_for_content_type(workflow.content_type)
    
    return "" if klass.nil?
    
    return "(#{h(klass.display_data_format)})"
  end
  
  def get_type_display_name(workflow)
    h(WorkflowTypesHandler.type_display_name_for_content_type(workflow.content_type))   
  end
  
end
