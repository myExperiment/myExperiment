# myExperiment: test/functional/blobs_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'blobs_controller'

class BlobsControllerTest < ActionController::TestCase
  fixtures :blobs, :users, :contributions, :content_blobs, :workflows, :packs, :policies, :permissions, :networks, :content_types

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
  
  def test_should_create_blob
    old_count = Blob.count

    login_as(:john)
    post :create, :blob => { :title => 'Test blob', :body => 'test test test', :license_id => 1, :data => fixture_file_upload('files/picture_1.png', 'image/png') }, 
                  :credits_me => 'false',
                  :credits_users => '',
                  :credits_groups => '',
                  :attributions_workflows => '',
                  :attributions_files => ''

    assert_equal old_count+1, Blob.count
    assert_redirected_to blob_path(assigns(:blob))
  end

  def test_should_create_blob_with_space
    old_count = Blob.count

    login_as(:john)
    post :create, :blob => { :title => 'Test blob', :body => 'test test test', :license_id => 1, :data => fixture_file_upload('files/picture space.png', 'image/png') },
                  :credits_me => 'false',
                  :credits_users => '',
                  :credits_groups => '',
                  :attributions_workflows => '',
                  :attributions_files => ''

    assert_equal old_count+1, Blob.count
    assert_redirected_to blob_path(assigns(:blob))
  end


  def test_should_show_blob
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_blob
    login_as(:john)
    put :update, :id => 1, :blob => { :title => 'Test blob - updated', :body => 'updated test test test' },
                           :credits_me => 'false',
                           :credits_users => '',
                           :credits_groups => '',
                           :attributions_workflows => '',
                           :attributions_files => ''

    assert_redirected_to blob_path(assigns(:blob))
  end
  
  def test_should_destroy_blob
    old_count = Blob.count
  
    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Blob.count   
    assert_redirected_to blobs_path
  end

  def test_should_apply_group_policy
    login_as(:john)
    old_policy_id = policies(:john_policy).id
    assert_difference("Policy.count", -1) do
      put :update, :id => 1, :blob => { :title => 'Test blob - updated', :body => 'updated test test test' },
                             :credits_me => 'false',
                             :credits_users => '',
                             :credits_groups => '',
                             :attributions_workflows => '',
                             :attributions_files => '',
                             :policy_type => "group",
                             :group_policy => "7"

      assert_redirected_to blob_path(assigns(:blob))
      assert_equal 7, assigns(:blob).contribution.policy_id
      assert_nil Policy.find_by_id(old_policy_id) # Old, custom policy should be deleted
    end
  end

  def test_should_apply_custom_policy
    login_as(:john)

    blob = blobs(:group_file_one)

    assert_difference("Policy.count", 1) do
      put :update, :id => blob.id, :blob => { :title => 'Updated', :body => 'updated test test test' },
                                   :credits_me => 'false',
                                   :credits_users => '',
                                   :credits_groups => '',
                                   :attributions_workflows => '',
                                   :attributions_files => '',
                                   :policy_type => "custom",
                                   :sharing => {:class_id => "1"},
                                   :updating => {:class_id => "1"}
      assert_not_equal 7, assigns(:blob).contribution.policy_id
      assert_equal 7, blobs(:group_file_two).contribution.policy_id
      assert_equal 0, blobs(:group_file_two).contribution.policy.share_mode
      assert_equal 1, assigns(:blob).contribution.policy.share_mode
    end

  end
end
