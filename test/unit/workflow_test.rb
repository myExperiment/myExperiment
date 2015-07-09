require File.dirname(__FILE__) + '/../test_helper'

class WorkflowTest < ActiveSupport::TestCase
  fixtures :workflows, :workflow_versions

  test "can mint DOI for workflow" do
    wf = workflows(:doiable_workflow)

    assert wf.mint_doi
    assert_equal "#{Conf.doi_prefix}wf/#{wf.id}", wf.doi
    assert_equal "http://test.host/workflows/#{wf.id}", DataciteClient.instance.resolve(wf.doi)
  end

  test "can mint DOI for workflow version" do
    v = workflow_versions(:doiable_workflow_v1)

    assert v.mint_doi
    assert_equal "#{Conf.doi_prefix}wf/#{v.workflow.id}.#{v.version}", v.doi
    assert_equal "http://test.host/workflows/#{v.workflow_id}?version=1", DataciteClient.instance.resolve(v.doi)
    assert_blank v.workflow.doi
  end

  test "can't mint DOI if an author's family/given names not set" do
    wf = workflows(:component_workflow)

    assert_raise RuntimeError do
      wf.mint_doi
    end
    assert wf.doi.blank?
    assert !DataciteClient.instance.resolve(wf.doi)
  end
end
