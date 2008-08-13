# myExperiment: test/functional/friendships_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'friendships_controller'

# Re-raise errors caught by the controller.
class FriendshipsController; def rescue_action(e) raise e end; end

class FriendshipsControllerTest < Test::Unit::TestCase
  fixtures :friendships, :users

  def setup
    @controller = FriendshipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:friendships)
  end

  def test_should_get_new
    login_as(:john)
    get :new, :user_id => '3'
    assert_response :success
  end
  
  def test_should_create_friendship
    old_count = Friendship.count

    login_as(:john)
    post :create, :friendship => { :user_id => '1', :friend_id => '3' }

    assert_equal old_count+1, Friendship.count    
    assert_redirected_to friendship_path('3', assigns(:friendship))
  end

  def test_should_show_friendship
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:jane)
    get :edit, :id => 1
    assert_response :success
  end
 
  # can't actually update a friendship, so this test isn't needed 
  def test_should_update_friendship
    login_as(:jane)
    put :update, :id => 1, :friendship => { }

    assert_response :success
  end
  
  def test_should_destroy_friendship
    old_count = Friendship.count

    login_as(:jane)
    delete :destroy, :id => 1

    assert_equal old_count-1, Friendship.count 
    assert_response :redirect
  end
end
