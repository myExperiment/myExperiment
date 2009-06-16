require File.dirname(__FILE__) + '/../test_helper'
require 'license_attributes_controller'

# Re-raise errors caught by the controller.
class LicenseAttributesController; def rescue_action(e) raise e end; end

class LicenseAttributesControllerTest < Test::Unit::TestCase
  def setup
    @controller = LicenseAttributesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
