require File.dirname(__FILE__) + '/../test_helper'
require 'policy_wizard_controller'

# Re-raise errors caught by the controller.
class PolicyWizardController; def rescue_action(e) raise e end; end

class PolicyWizardControllerTest < Test::Unit::TestCase
  def setup
    @controller = PolicyWizardController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
