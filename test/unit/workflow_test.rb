require File.dirname(__FILE__) + '/../test_helper'

class WorkflowTest < ActiveSupport::TestCase
  fixtures :workflows

  test "can generate RDF" do
    assert !workflows(:component_workflow).to_rdf.empty?
  end

end
