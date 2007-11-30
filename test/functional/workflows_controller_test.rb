# myExperiment: test/functional/workflows_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'

# Re-raise errors caught by the controller.
class WorkflowsController; def rescue_action(e) raise e end; end

class WorkflowsControllerTest < Test::Unit::TestCase
  fixtures :workflows

  def setup
    @controller = WorkflowsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:workflows)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_workflow
    old_count = Workflow.count
    post :create, :workflow => { }
    assert_equal old_count+1, Workflow.count

    assert_redirected_to workflow_path(assigns(:workflow))
  end

  def test_should_show_workflow
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_workflow
    put :update, :id => 1, :workflow => { }
    assert_redirected_to workflow_path(assigns(:workflow))
  end

  def test_should_destroy_workflow
    old_count = Workflow.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Workflow.count

    assert_redirected_to workflows_path
  end
end
