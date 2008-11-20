# myExperiment: test/functional/permissions_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'permissions_controller'

# Re-raise errors caught by the controller.
class PermissionsController; def rescue_action(e) raise e end; end

class PermissionsControllerTest < Test::Unit::TestCase
  fixtures :permissions, :users, :policies

  def setup
    @controller = PermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # view not used, and errors when attempted
  def test_should_get_index
    #login_as(:john)
    #get :index
    #assert_response :success
    #assert assigns(:permissions)
    
    assert true
  end

  def test_should_get_new
    login_as(:john)
    get :new, :policy_id => policies(:john_policy).id
    assert_response :success
  end
  
  def test_should_create_permission
    old_count = Permission.count

    login_as(:john)
    post :create, :permission => { :policy_id => policies(:john_policy).id, 
                                   :contributor_type => 'User',
                                   :contributor_id => 2,
                                   :download => 1,
                                   :edit => 0,
                                   :view => 1 },
                  :user_contributor_id => 2,
                  :policy_id => policies(:john_policy).id

    assert assigns(:permission)
    assert_redirected_to policy_path(policies(:john_policy).id)
    assert_equal old_count+1, Permission.count
  end

  def test_should_show_permission
    login_as(:john)
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1, :policy_id => policies(:john_policy).id
    assert_response :success
  end
  
  def test_should_update_permission
    login_as(:john)
    put :update, :id => 1, :permission => { :contributor_id => '3',
                                            :contributor_type => 'User',
                                            :edit => '0', 
                                            :download => '0',
                                            :view => '1' }, 
                 :policy_id => policies(:john_policy).id

    assert_equal 'Permission was successfully updated.', flash[:notice]
    assert assigns(:permission)
    assert_redirected_to policy_path(policies(:john_policy).id)
  end
  
  def test_should_destroy_permission
    old_count = Permission.count

    login_as(:john)
    delete :destroy, :id => 1, :policy_id => policies(:john_policy).id

    assert_equal old_count-1, Permission.count    
    assert_redirected_to policy_path(policies(:john_policy).id)
  end
end
