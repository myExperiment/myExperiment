require File.dirname(__FILE__) + '/../test_helper'
require 'viewings_controller'

# Re-raise errors caught by the controller.
class ViewingsController; def rescue_action(e) raise e end; end

class ViewingsControllerTest < Test::Unit::TestCase
  fixtures :viewings

  def setup
    @controller = ViewingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:viewings)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_viewing
    old_count = Viewing.count
    post :create, :viewing => { }
    assert_equal old_count+1, Viewing.count
    
    assert_redirected_to viewing_path(assigns(:viewing))
  end

  def test_should_show_viewing
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_viewing
    put :update, :id => 1, :viewing => { }
    assert_redirected_to viewing_path(assigns(:viewing))
  end
  
  def test_should_destroy_viewing
    old_count = Viewing.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Viewing.count
    
    assert_redirected_to viewings_path
  end
end
