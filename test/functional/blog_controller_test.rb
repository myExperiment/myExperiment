require File.dirname(__FILE__) + '/../test_helper'
require 'blog_controller'

# Re-raise errors caught by the controller.
class BlogController; def rescue_action(e) raise e end; end

class BlogControllerTest < Test::Unit::TestCase
  fixtures :blogs

  def setup
    @controller = BlogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = blogs(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:blogs)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:blog)
    assert assigns(:blog).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:blog)
  end

  def test_create
    num_blogs = Blog.count

    post :create, :blog => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_blogs + 1, Blog.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:blog)
    assert assigns(:blog).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Blog.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Blog.find(@first_id)
    }
  end
end
