require File.dirname(__FILE__) + '/../test_helper'
require 'mashup_controller'

# Re-raise errors caught by the controller.
class MashupController; def rescue_action(e) raise e end; end

class MashupControllerTest < Test::Unit::TestCase
  def setup
    @controller = MashupController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
