require File.dirname(__FILE__) + '/../test_helper'
require 'openid_controller'

# Re-raise errors caught by the controller.
class OpenidController; def rescue_action(e) raise e end; end

# NOTE: if you get the message 'undefined method `require_gem' for main:Object (NoMethodError)'
#  when running these tests, change 'require_gem' to 'gem' in openid_controller
class OpenidControllerTest < Test::Unit::TestCase
  def setup
    @controller = OpenidController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
