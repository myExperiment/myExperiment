# myExperiment: test/functional/policies_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'policies_controller'

# Re-raise errors caught by the controller.
class PoliciesController; def rescue_action(e) raise e end; end

class PoliciesControllerTest < Test::Unit::TestCase
  fixtures :policies, :users

  def setup
    @controller = PoliciesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    login_as(:john)
    get :index
    assert_response :success
    assert assigns(:policies)
  end

  def test_should_get_new
    login_as(:john)
    get :new
    assert_response :success
  end
  
  def test_should_create_policy
    old_count = Policy.count

    login_as(:john)
    post :create, :policy => { :contributor_id => users(:john).id,
                               :contributor_type => 'User',
                               :name => 'test policy',
                               :view_public => true,
                               :download_public => true,
                               :edit_public => true,
                               :view_protected => true,
                               :download_protected => true,
                               :edit_protected => true }

    assert_equal old_count+1, Policy.count    
    assert_redirected_to policy_path(assigns(:policy))
  end

  def test_should_show_policy
    login_as(:john)
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_policy
    login_as(:john)
    put :update, :id => 1, :policy => { :download_public => false, :edit_public => false }
    assert_redirected_to policy_path(assigns(:policy))
  end
  
  def test_should_destroy_policy
    old_count = Policy.count

    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Policy.count
    assert_redirected_to policies_path
  end
end
