# myExperiment: test/functional/bookmarks_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'bookmarks_controller'

# Re-raise errors caught by the controller.
class BookmarksController; def rescue_action(e) raise e end; end

class BookmarksControllerTest < Test::Unit::TestCase
  def setup
    @controller = BookmarksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
