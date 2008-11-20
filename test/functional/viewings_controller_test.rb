require File.dirname(__FILE__) + '/../test_helper'
require 'viewings_controller'

# Re-raise errors caught by the controller.
class ViewingsController; def rescue_action(e) raise e end; end

class ViewingsControllerTest < Test::Unit::TestCase
  fixtures :viewings, :users, :contributions, :workflows, :blobs, :packs

  def setup
    @controller = ViewingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index, :contribution_id => contributions(:contribution_workflow_1).id
    assert_response :success
    assert assigns(:viewings)
  end

  # cannot directly create new viewing
  def test_should_get_new
    get :new
    assert_response :redirect
  end
  
  # cannot directly create new viewing
  def test_should_create_viewing
    post :create, :viewing => { }
    assert_response :redirect
  end

  def test_should_show_viewing
    get :show, :id => 1, :contribution_id => contributions(:contribution_workflow_1).id
    assert_response :success
  end

  # cannot edit a viewing
  def test_should_get_edit
    get :edit, :id => 1
    assert_response :redirect
  end
  
  # cannot update a viewing
  def test_should_update_viewing
    put :update, :id => 1, :viewing => { }
    assert_response :redirect
  end
  
  # cannot destroy a viewing
  def test_should_destroy_viewing
    delete :destroy, :id => 1    
    assert_response :redirect
  end
end
