require File.dirname(__FILE__) + '/../test_helper'

class WorkflowTest < ActiveSupport::TestCase
  fixtures :workflows

  test "can mint DOI" do
    wf = workflows(:doiable_workflow)

    assert wf.mint_doi
    assert !wf.doi.blank?
    assert_equal "http://test.host/workflows/#{wf.id}", DataciteClient.instance.resolve(wf.doi)
  end

  test "can't mint DOI if family/given names not set" do
    wf = workflows(:component_workflow)

    assert_raise RuntimeError do
      wf.mint_doi
    end
    assert wf.doi.blank?
    assert !DataciteClient.instance.resolve(wf.doi)
  end
end
