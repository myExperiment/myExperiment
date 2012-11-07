class WsdlDeprecation < ActiveRecord::Base

  validates_uniqueness_of :wsdl

  def affected_workflows
    WorkflowProcessor.find_all_by_wsdl(wsdl, :include => :workflow).uniq.compact
  end

end
