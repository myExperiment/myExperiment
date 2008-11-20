# myExperiment: test/functional/blogs_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'blogs_controller'

# Re-raise errors caught by the controller.
class BlogsController; def rescue_action(e) raise e end; end

class BlogsControllerTest < Test::Unit::TestCase

  def test_true
    assert true
  end

end
