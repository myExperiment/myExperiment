require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :users, :workflows, :bookmarks

  test 'can get bookmarks' do
    u = users(:john)
    b = bookmarks(:bookmark_workflow_1)
    w = b.bookmarkable

    assert u.bookmarks.any?
    assert_includes u.bookmarks, b
    assert_includes u.bookmarked_items, w
  end
end
