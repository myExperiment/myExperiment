# myExperiment: test/functional/pictures_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'pictures_controller'

# Re-raise errors caught by the controller.
class PicturesController; def rescue_action(e) raise e end; end

class PicturesControllerTest < Test::Unit::TestCase
  fixtures :pictures

  def setup
    @controller = PicturesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:pictures)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_picture
    old_count = Picture.count
    post :create, :picture => { }
    assert_equal old_count+1, Picture.count
    
    assert_redirected_to picture_path(assigns(:picture))
  end

  def test_should_show_picture
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_picture
    put :update, :id => 1, :picture => { }
    assert_redirected_to picture_path(assigns(:picture))
  end
  
  def test_should_destroy_picture
    old_count = Picture.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Picture.count
    
    assert_redirected_to pictures_path
  end
end
