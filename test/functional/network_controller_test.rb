require File.dirname(__FILE__) + '/../test_helper'
require 'network_controller'

# Re-raise errors caught by the controller.
class NetworkController; def rescue_action(e) raise e end; end

class NetworkControllerTest < Test::Unit::TestCase
  def setup
    @controller = NetworkController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
