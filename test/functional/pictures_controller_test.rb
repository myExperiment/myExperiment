# myExperiment: test/functional/pictures_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'pictures_controller'

# Re-raise errors caught by the controller.
class PicturesController; def rescue_action(e) raise e end; end

class PicturesControllerTest < Test::Unit::TestCase
  fixtures :pictures, :users, :picture_selections, :profiles

  def setup
    @controller = PicturesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    login_as(:john)
    get :index, :user_id => users(:john).id

    assert_response :success
    assert assigns(:pictures)
  end

  def test_should_get_new
    login_as(:john)
    get :new, :user_id => users(:john).id

    assert_response :success
  end
 
  # posting multipart data not supported in tests? doesn't seem to work 
  def test_should_create_picture
    #old_count = Picture.count

    #login_as(:john)
    # post :create, :picture => { :data => fixture_file_upload('files/picture_2.png', 'image/png'), :multipart => true }, :multipart => true

    #assert_equal old_count+1, Picture.count    
    #assert_redirected_to picture_path(assigns(:picture))

    assert true
  end

  def test_should_show_picture
    get :show, :id => 1
    assert_response :success
  end

  # can't edit a picture
  def test_should_get_edit
    get :edit, :id => 1
    assert_response :redirect
  end
  
  # can't update a picture
  def test_should_update_picture
    put :update, :id => 1, :picture => { }
    assert_response :redirect
  end
  
  def test_should_destroy_picture
    old_count = Picture.count

    login_as(:john)
    delete :destroy, :id => 1, :user_id => users(:john).id

    assert_equal old_count-1, Picture.count    
    assert_redirected_to user_pictures_path(users(:john).id)
  end
end
