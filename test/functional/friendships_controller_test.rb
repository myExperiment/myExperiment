# myExperiment: test/functional/friendships_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'friendships_controller'

# Re-raise errors caught by the controller.
class FriendshipsController; def rescue_action(e) raise e end; end

class FriendshipsControllerTest < Test::Unit::TestCase
  fixtures :friendships, :users, :profiles

  def setup
    @controller = FriendshipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    login_as(:john)
    get :index, :user_id => users(:john).id

    assert_response :success
    assert assigns(:friendships)
  end

  def test_should_get_new
    login_as(:john)
    get :new, :user_id => users(:admin).id
    assert_response :success
  end
  
  def test_should_create_friendship
    old_count = Friendship.count

    login_as(:john)
    post :create, :user_id => users(:admin).id, :friendship => { :user_id => users(:john).id, :friend_id => users(:admin).id }

    assert_equal old_count+1, Friendship.count    
    assert_redirected_to user_friendship_path(users(:john).id, assigns(:friendship))
  end

  def test_should_show_friendship
    login_as(:john)
    get :show, :user_id => users(:john).id, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:jane)
    get :edit, :user_id => users(:jane).id, :id => 1
    assert_response :success
  end
 
  # can't actually update a friendship, so this test isn't needed 
  def test_should_update_friendship
    login_as(:jane)
    put :update, :user_id => users(:jane).id, :id => 1, :friendship => { }

    assert_response :success
  end
  
  def test_should_destroy_friendship
    old_count = Friendship.count

    login_as(:jane)
    delete :destroy, :user_id => users(:jane).id, :id => 1

    assert_equal old_count-1, Friendship.count 
    assert_response :redirect
  end
end
