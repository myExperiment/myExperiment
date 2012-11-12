class WsdlDeprecation < ActiveRecord::Base

  validates_uniqueness_of :wsdl, :scope => :deprecation_event_id
  belongs_to :deprecation_event

  def affected_workflows
    WorkflowProcessor.find_all_by_wsdl(wsdl, :include => :workflow).map {|wp| wp.workflow}.uniq.compact
  end

end
