require File.dirname(__FILE__) + '/../test_helper'
require 'downloads_controller'

# Re-raise errors caught by the controller.
class DownloadsController; def rescue_action(e) raise e end; end

class DownloadsControllerTest < Test::Unit::TestCase
  fixtures :downloads, :users, :contributions, :workflows, :workflow_versions, :blobs, :packs, :policies, :permissions, :profiles, :pictures, :picture_selections

  def setup
    @controller = DownloadsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index, :contribution_id => contributions(:contribution_workflow_1).id
    assert_response :success
    assert assigns(:downloads)
  end

  # cannot explicitly create new download
  def test_should_get_new
    get :new
    assert_response :redirect
  end
  
  # cannot explicitly create new download
  def test_should_create_download
    post :create, :download => { }
    assert_response :redirect
  end

  # not used on site so not worth testing
  def test_should_show_download
    #login_as(:john)
    #get :show, :id => 1, :contribution_id => contributions(:contribution_workflow_1).id
    #assert_response :success

    assert true
  end

  # cannot edit a download
  def test_should_get_edit
    get :edit, :id => 1
    assert_response :redirect
  end
  
  # cannot update a download
  def test_should_update_download
    put :update, :id => 1, :download => { }
    assert_response :redirect
  end
  
  # cannot destroy a download
  def test_should_destroy_download
    delete :destroy, :id => 1
    assert_response :redirect
  end
end
