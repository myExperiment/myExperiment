require File.dirname(__FILE__) + '/../test_helper'
require 'group_policies_controller'

class GroupPoliciesControllerTest < ActionController::TestCase
  fixtures :policies, :blobs, :permissions, :networks, :users

  def test_administrators_can_view
    login_as(:john)
    get :index, :network_id => networks(:exclusive_network).id
    assert_response :success
  end

  def test_non_admins_cannot_view
    login_as(:jane)
    get :index, :network_id => networks(:exclusive_network).id
    assert_response :redirect
  end

  def test_can_create
    login_as(:john)

    assert_difference("Policy.count", 1) do
      post :create, :network_id => networks(:exclusive_network).id,
                    :name => "New Policy", :share_mode  => 0
    end
  end

  def test_can_delete_if_not_used
    login_as(:john)

    assert_difference("Policy.count", -1) do
      delete :destroy, :network_id => networks(:exclusive_network).id, :id => policies(:unused_group_policy).id
      assert_response :redirect
    end
  end

  def test_cannot_delete_if_used
    login_as(:john)

    assert_no_difference("Policy.count") do
      delete :destroy, :network_id => networks(:exclusive_network).id, :id => policies(:group_policy).id
      assert_response :redirect
    end
  end

  def test_can_update
    login_as(:john)

    assert_equal 0, policies(:group_policy).share_mode

    put :update, :network_id => networks(:exclusive_network).id, :id => policies(:group_policy).id,
                 :share_mode  => 2

    assert_response :success

    assert_equal 2, assigns(:policy).share_mode
  end

end