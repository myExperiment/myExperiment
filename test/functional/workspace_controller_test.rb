require File.dirname(__FILE__) + '/../test_helper'
require 'workspace_controller'

# Re-raise errors caught by the controller.
class WorkspaceController; def rescue_action(e) raise e end; end

class WorkspaceControllerTest < Test::Unit::TestCase
  def setup
    @controller = WorkspaceController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
