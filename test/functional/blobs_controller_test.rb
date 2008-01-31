# myExperiment: test/functional/blobs_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'blobs_controller'

# Re-raise errors caught by the controller.
class BlobsController; def rescue_action(e) raise e end; end

class BlobsControllerTest < Test::Unit::TestCase
  fixtures :blobs

  def setup
    @controller = BlobsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:blobs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_blob
    old_count = Blob.count
    post :create, :blob => { }
    assert_equal old_count+1, Blob.count
    
    assert_redirected_to blob_path(assigns(:blob))
  end

  def test_should_show_blob
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_blob
    put :update, :id => 1, :blob => { }
    assert_redirected_to blob_path(assigns(:blob))
  end
  
  def test_should_destroy_blob
    old_count = Blob.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Blob.count
    
    assert_redirected_to blobs_path
  end
end
