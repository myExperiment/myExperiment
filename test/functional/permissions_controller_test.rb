# myExperiment: test/functional/permissions_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'permissions_controller'

# Re-raise errors caught by the controller.
class PermissionsController; def rescue_action(e) raise e end; end

class PermissionsControllerTest < Test::Unit::TestCase
  fixtures :permissions

  def setup
    @controller = PermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:permissions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_permission
    old_count = Permission.count
    post :create, :permission => { }
    assert_equal old_count+1, Permission.count
    
    assert_redirected_to permission_path(assigns(:permission))
  end

  def test_should_show_permission
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_permission
    put :update, :id => 1, :permission => { }
    assert_redirected_to permission_path(assigns(:permission))
  end
  
  def test_should_destroy_permission
    old_count = Permission.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Permission.count
    
    assert_redirected_to permissions_path
  end
end
