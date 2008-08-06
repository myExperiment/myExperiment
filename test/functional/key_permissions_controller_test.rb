require File.dirname(__FILE__) + '/../test_helper'
require 'key_permissions_controller'

# Re-raise errors caught by the controller.
class KeyPermissionsController; def rescue_action(e) raise e end; end

class KeyPermissionsControllerTest < Test::Unit::TestCase
  def setup
    @controller = KeyPermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
