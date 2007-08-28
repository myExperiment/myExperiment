require File.dirname(__FILE__) + '/../test_helper'
require 'todos_controller'

# Re-raise errors caught by the controller.
class TodosController; def rescue_action(e) raise e end; end

class TodosControllerTest < Test::Unit::TestCase
  fixtures :todos

  def setup
    @controller = TodosController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = todos(:first).id
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

    assert_not_nil assigns(:todos)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:todo)
    assert assigns(:todo).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:todo)
  end

  def test_create
    num_todos = Todo.count

    post :create, :todo => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_todos + 1, Todo.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:todo)
    assert assigns(:todo).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Todo.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Todo.find(@first_id)
    }
  end
end
