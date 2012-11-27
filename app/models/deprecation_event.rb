class DeprecationEvent < ActiveRecord::Base

  has_many :wsdl_deprecations
  validates_presence_of :date

  def affected_workflows
    WorkflowProcessor.find_all_by_wsdl(wsdl_deprecations.map {|wd| wd.wsdl}, :include => :workflow).map {|wp| wp.workflow}.uniq.compact
  end

end
