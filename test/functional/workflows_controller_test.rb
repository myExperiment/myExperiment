# myExperiment: test/functional/workflows_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'
require 'xml/libxml'

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
    post :create, :workflow => { :file => fixture_file_upload('files/workflow_dilbert.xml'), :license_id => '1' },
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

  def test_workflow_api
    login_as(:john)

    content = LibXML::XML::Node.new("content") <<
      Base64.encode64(File.read('test/fixtures/files/workflow_dilbert.xml'))

    content["encoding"] = "base64"

    doc = LibXML::XML::Document.new
    doc.root = LibXML::XML::Node.new("workflow")

    {
      "title"        => "Test title",
      "description"  => "Test description.",
      "license-type" => "by-sa",
      "content-type" => "application/vnd.taverna.scufl+xml",
      "content"      => content
    }.each do |k, v|
      doc.root << (LibXML::XML::Node.new(k) << v)
    end

  end
end
