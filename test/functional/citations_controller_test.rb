require File.dirname(__FILE__) + '/../test_helper'
require 'citations_controller'

# Re-raise errors caught by the controller.
class CitationsController; def rescue_action(e) raise e end; end

class CitationsControllerTest < Test::Unit::TestCase
  fixtures :citations

  def setup
    @controller = CitationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:citations)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_citation
    old_count = Citation.count
    post :create, :citation => { }
    assert_equal old_count+1, Citation.count
    
    assert_redirected_to citation_path(assigns(:citation))
  end

  def test_should_show_citation
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_citation
    put :update, :id => 1, :citation => { }
    assert_redirected_to citation_path(assigns(:citation))
  end
  
  def test_should_destroy_citation
    old_count = Citation.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Citation.count
    
    assert_redirected_to citations_path
  end
end
