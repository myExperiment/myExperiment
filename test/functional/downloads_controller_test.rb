require File.dirname(__FILE__) + '/../test_helper'
require 'downloads_controller'

# Re-raise errors caught by the controller.
class DownloadsController; def rescue_action(e) raise e end; end

class DownloadsControllerTest < Test::Unit::TestCase
  fixtures :downloads

  def setup
    @controller = DownloadsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:downloads)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_download
    old_count = Download.count
    post :create, :download => { }
    assert_equal old_count+1, Download.count
    
    assert_redirected_to download_path(assigns(:download))
  end

  def test_should_show_download
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_download
    put :update, :id => 1, :download => { }
    assert_redirected_to download_path(assigns(:download))
  end
  
  def test_should_destroy_download
    old_count = Download.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Download.count
    
    assert_redirected_to downloads_path
  end
end
