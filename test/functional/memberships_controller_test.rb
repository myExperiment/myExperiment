# myExperiment: test/functional/memberships_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'memberships_controller'

# Re-raise errors caught by the controller.
class MembershipsController; def rescue_action(e) raise e end; end

class MembershipsControllerTest < Test::Unit::TestCase
  fixtures :memberships, :users, :networks

  def setup
    @controller = MembershipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    login_as(:john)
    get :index, :user_id => users(:john).id

    assert_response :success
    assert assigns(:memberships)
  end

  def test_should_get_new
    login_as(:john)
    get :new, :user_id => 'users(:john).id'

    assert_response :success
  end
  
  def test_should_create_membership
    old_count = Membership.count

    login_as(:john)
    post :create, :user_id => users(:john).id, 
                  :membership => { :user_id => users(:john).id, :network_id => networks(:spare_network).id } #, :message => "Can I Join Please?" }

    assert_equal old_count+1, Membership.count
    assert_redirected_to user_membership_path(users(:john).id, assigns(:membership))
  end

  # not convinced that this test is working
  def test_should_show_membership
    login_as(:john)
    get :show, :user_id => users(:john).id, :id => 2
    assert_response :success
  end

  # can't edit a membership record, always redirects
  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1
    assert_response :redirect
  end
  
  # if you can't edit a membership, you probably can't update it either
  def test_should_update_membership
    login_as(:john)
    put :update, :id => 1, :membership => { }
    assert_response :redirect
  end
  
  def test_should_destroy_membership
    old_count = Membership.count

    login_as(:john)
    delete :destroy, :id => networks(:another_network).id, :user_id => users(:john).id

    assert_redirected_to group_path(networks(:another_network).id )
    assert_equal old_count-1, Membership.count
  end
end
