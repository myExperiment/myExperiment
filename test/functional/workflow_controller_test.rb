require File.dirname(__FILE__) + '/../test_helper'
require 'workflow_controller'

# Re-raise errors caught by the controller.
class WorkflowController; def rescue_action(e) raise e end; end

class WorkflowControllerTest < Test::Unit::TestCase
  fixtures :workflows

  def setup
    @controller = WorkflowController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = workflows(:first).id
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

    assert_not_nil assigns(:workflows)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:workflow)
    assert assigns(:workflow).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:workflow)
  end

  def test_create
    num_workflows = Workflow.count

    post :create, :workflow => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_workflows + 1, Workflow.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:workflow)
    assert assigns(:workflow).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Workflow.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Workflow.find(@first_id)
    }
  end
end
