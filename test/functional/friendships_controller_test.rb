require File.dirname(__FILE__) + '/../test_helper'
require 'friendships_controller'

# Re-raise errors caught by the controller.
class FriendshipsController; def rescue_action(e) raise e end; end

class FriendshipsControllerTest < Test::Unit::TestCase
  fixtures :friendships

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
    get :new
    assert_response :success
  end
  
  def test_should_create_friendship
    old_count = Friendship.count
    post :create, :friendship => { }
    assert_equal old_count+1, Friendship.count
    
    assert_redirected_to friendship_path(assigns(:friendship))
  end

  def test_should_show_friendship
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_friendship
    put :update, :id => 1, :friendship => { }
    assert_redirected_to friendship_path(assigns(:friendship))
  end
  
  def test_should_destroy_friendship
    old_count = Friendship.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Friendship.count
    
    assert_redirected_to friendships_path
  end
end
