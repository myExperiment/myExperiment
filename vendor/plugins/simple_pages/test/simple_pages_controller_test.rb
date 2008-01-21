require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../../../../config/environment')
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')
require File.expand_path(File.dirname(__FILE__)) + '/../app/controllers/simple_pages_controller'

# Re-raise errors caught by the controller.
class SimplePagesController
  def rescue_action(e) raise e end;
  def can_manage_pages?; true end;
end

class SimplePagesControllerTest < Test::Unit::TestCase

  def setup
    @controller = SimplePagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_index
    test_create # put something in the db
    get :index
    assert_response :success
    assert assigns(:simple_pages)
    assert_kind_of SimplePage, assigns(:simple_pages).first
  end
  
  def test_new
    get :new
    assert_response :success
    assert assigns(:simple_page).new_record?
  end
  
  def test_edit
    test_create # put something in the db again
    get :edit, :id => 'test_create'
    assert_response :success
    assert !assigns(:simple_page).new_record?
  end
  
  def test_show
    sp = SimplePage.create(:filename => 'test_show', :title => 'Test Show', :content => '<h1>Content!</h1>')
    get :show, :id => 'test_show'
    assert_response :success
    assert_equal sp, assigns(:simple_page)
    assert !assigns(:simple_page).new_record?
  end
  
  def test_create
    post :create, :simple_page => { :filename => 'test_create', :title => 'Test Create', :content => '<h1>Content!</h1>'  }
    assert_redirected_to simple_page_path(SimplePage.find_by_filename('test_create'))
    assert assigns(:simple_page).valid?
    assert !assigns(:simple_page).new_record?
    assert flash[:success]
  end
  
  def test_update
    sp = SimplePage.create(:filename => 'test_update', :title => 'Test Update', :content => '<h1>Content!</h1>')
    put :update, :id => 'test_update', :simple_page => { :filename => 'test_update_new', :title => 'Test Update - NEW!', :content => '<h1>Content!</h1>'  }
    assert assigns(:simple_page).valid?
    assert_redirected_to simple_page_path(SimplePage.find_by_filename('test_update_new'))
    assert flash[:success]
  end
  
  def test_destroy
    sp = SimplePage.create(:filename => 'test_destroy', :title => 'Test Destroy', :content => '<h1>Content!</h1>')
    delete :destroy, :id => 'test_destroy'
    assert_redirected_to simple_pages_path
    assert assigns(:simple_page).frozen?
    assert_raises(ActiveRecord::RecordNotFound) {SimplePage.find('test_destroy')}
  end

end
