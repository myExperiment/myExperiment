# myExperiment: test/functional/blobs_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'blobs_controller'

# Re-raise errors caught by the controller.
class BlobsController; def rescue_action(e) raise e end; end

class BlobsControllerTest < Test::Unit::TestCase
  fixtures :blobs, :users, :contributions, :content_blobs, :workflows, :packs, :policies, :permissions, :networks, :content_types

  def setup
    @controller = BlobsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_should_get_new
    login_as(:john)
    get :new
    assert_response :success
  end
  
  def test_should_create_blob
    old_count = Blob.count

    login_as(:john)
    post :create, :blob => { :title => 'Test blob', :body => 'test test test', :data => fixture_file_upload('files/picture_1.png', 'image/png') }, 
                  :credits_me => 'false',
                  :credits_users => '',
                  :credits_groups => '',
                  :attributions_workflows => '',
                  :attributions_files => ''

    assert_equal old_count+1, Blob.count
    assert_redirected_to file_path(assigns(:blob))
  end

  def test_should_show_blob
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_blob
    login_as(:john)
    put :update, :id => 1, :blob => { :title => 'Test blob - updated', :body => 'updated test test test' },
                           :credits_me => 'false',
                           :credits_users => '',
                           :credits_groups => '',
                           :attributions_workflows => '',
                           :attributions_files => ''

    assert_redirected_to file_path(assigns(:blob))
  end
  
  def test_should_destroy_blob
    old_count = Blob.count
  
    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Blob.count   
    assert_redirected_to files_path
  end
end
