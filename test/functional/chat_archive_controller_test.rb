require File.dirname(__FILE__) + '/../test_helper'
require 'chat_archive_controller'

# Re-raise errors caught by the controller.
class ChatArchiveController; def rescue_action(e) raise e end; end

class ChatArchiveControllerTest < Test::Unit::TestCase
  def setup
    @controller = ChatArchiveController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
