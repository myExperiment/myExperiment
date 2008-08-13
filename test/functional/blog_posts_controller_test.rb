# myExperiment: test/functional/blog_posts_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'blog_posts_controller'

# Re-raise errors caught by the controller.
class BlogPostsController; def rescue_action(e) raise e end; end

class BlogPostsControllerTest < Test::Unit::TestCase

  def test_true
    assert true
  end

end
