# myExperiment: test/functional/workflows_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'

# Re-raise errors caught by the controller.
class WorkflowsController; def rescue_action(e) raise e end; end

class WorkflowsControllerTest < Test::Unit::TestCase
  fixtures :workflows, :users, :contributions, :workflow_versions, :content_blobs, :blobs, :packs, :policies, :permissions, :networks, :content_types

  def setup
    @controller = WorkflowsController.new
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

  def test_should_create_workflow
    old_count = Workflow.count

    login_as(:john)
    post :create, :workflow => { :file => fixture_file_upload('files/workflow_dilbert.xml'), :license => 'by-sa' },
                  :metadata_choice => 'infer',
                  :credits_me => 'false',
                  :credits_users => '',
                  :credits_groups => '',
                  :attributions_workflows => '',
                  :attributions_files => ''

    assert_redirected_to workflow_path(assigns(:workflow))
    assert_equal old_count+1, Workflow.count
  end

  def test_should_show_workflow
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1

    assert_response :success
  end

  def test_should_update_workflow
    login_as(:john)
    put :update, :id => 1, :workflow => { },
                           :credits_me => 'false',
                           :credits_users => '',
                           :credits_groups => '',
                           :attributions_workflows => '',
                           :attributions_files => ''

    assert_redirected_to workflow_path(assigns(:workflow))
  end

  def test_should_destroy_workflow
    old_count = Workflow.count

    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Workflow.count
    assert_redirected_to workflows_path
  end
end
