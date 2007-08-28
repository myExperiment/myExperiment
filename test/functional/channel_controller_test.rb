require File.dirname(__FILE__) + '/../test_helper'
require 'channel_controller'

# Re-raise errors caught by the controller.
class ChannelController; def rescue_action(e) raise e end; end

class ChannelControllerTest < Test::Unit::TestCase
  def setup
    @controller = ChannelController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
