require File.dirname(__FILE__) + '/../test_helper'
require 'hyperlinks_controller'

# Re-raise errors caught by the controller.
class HyperlinksController; def rescue_action(e) raise e end; end

class HyperlinksControllerTest < Test::Unit::TestCase
  fixtures :hyperlinks

  def setup
    @controller = HyperlinksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:hyperlinks)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_hyperlink
    old_count = Hyperlink.count
    post :create, :hyperlink => { }
    assert_equal old_count+1, Hyperlink.count
    
    assert_redirected_to hyperlink_path(assigns(:hyperlink))
  end

  def test_should_show_hyperlink
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_hyperlink
    put :update, :id => 1, :hyperlink => { }
    assert_redirected_to hyperlink_path(assigns(:hyperlink))
  end
  
  def test_should_destroy_hyperlink
    old_count = Hyperlink.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Hyperlink.count
    
    assert_redirected_to hyperlinks_path
  end
end
