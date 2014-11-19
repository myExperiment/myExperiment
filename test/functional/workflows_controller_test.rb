# encoding: utf-8
# myExperiment: test/functional/workflows_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require_relative '../test_helper'
require 'workflows_controller'

class WorkflowsControllerTest < ActionController::TestCase
  fixtures :workflows, :users, :contributions, :workflow_versions, :content_blobs, :blobs, :packs, :policies, :permissions, :networks, :content_types

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

    # Test searches

    workflow = Workflow.last

    # Basic test that the workflow was indexed in Solr and that it appears in a search result.
    assert Workflow.search { fulltext "dilbert" }.results.include?(workflow) if Conf.solr_enable
  end

  def test_should_create_version_with_workflow
    old_version_count = WorkflowVersion.count

    login_as(:john)
    post :create, :workflow => { :file => fixture_file_upload('files/workflow_dilbert.xml'), :license_id => '1' },
                  :metadata_choice => 'infer',
                  :credits_me => 'false',
                  :credits_users => '',
                  :credits_groups => '',
                  :attributions_workflows => '',
                  :attributions_files => ''

    assert_redirected_to workflow_path(assigns(:workflow))
    assert_equal old_version_count+1, WorkflowVersion.count
    assert !assigns(:workflow).find_version(1).nil?
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

  def test_should_store_workflow_rdf
    login_as(:john)

    # Clear test repo
    TripleStore.instance.repo = {}

    assert_difference('Workflow.count', 1) do
     post :create, :workflow => { :file => fixture_file_upload('files/image_to_tiff_migration.t2flow'), :license_id => '1' },
                   :metadata_choice => 'infer',
                   :credits_me => 'false',
                   :credits_users => '',
                   :credits_groups => '',
                   :attributions_workflows => '',
                   :attributions_files => ''
    end

    # Was it inserted into the triple store on save?
    assert_equal 1, TripleStore.instance.repo.keys.size

    delete :destroy, :id => assigns(:workflow).id

    # Was it deleted from the triple store on delete?
    assert_equal 0, TripleStore.instance.repo.keys.size

    TripleStore.instance.repo = {}
  end

  def test_can_tag_workflow
    login_as(:john)
    wf = workflows(:workflow_dilbert)

    assert_equal 0, wf.tags.size

    post :tag, :id => wf.id, :tag_list => 'new tag, utf-8 ㈛ ㈘ ㈔'

    assert_response :success
    assert_equal 2, wf.tags.size
    assert_includes wf.tags.map {|t| t.name}, 'utf-8 ㈛ ㈘ ㈔'
    assert_includes wf.tags.map {|t| t.name}, 'new tag'
  end

  test "can add workflow to favourites" do
    login_as(:john)
    wf = workflows(:workflow_branch_choice)

    assert_equal 0, wf.bookmarks.size

    assert_difference('Bookmark.count', 1) do
      post :favourite, :id => wf.id
    end

    assert_response :redirect
    assert_equal users(:john), wf.reload.bookmarks.first.user
  end

  test "can remove workflow from favourites" do
    login_as(:john)
    wf = workflows(:workflow_dilbert)

    assert_equal 1, wf.bookmarks.size

    assert_difference('Bookmark.count', -1) do
      delete :favourite_delete, :id => wf.id
    end

    assert_response :redirect
  end
end
