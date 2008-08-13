# myExperiment: test/functional/contributions_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'contributions_controller'

# Re-raise errors caught by the controller.
class ContributionsController; def rescue_action(e) raise e end; end

class ContributionsControllerTest < Test::Unit::TestCase
  fixtures :contributions, :users, :workflows, :workflow_versions, :blobs, :packs, :policies, :permissions

  def setup
    @controller = ContributionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # not used on site
  def test_should_get_index
    #get :index
    #assert_response :success
    #assert assigns(:contributions)

    assert true
  end

  # not used directly
  def test_should_get_new
    #login_as(:john)
    #get :new
    #assert_response :success

    assert true
  end
  
  def test_should_create_contribution
    old_count = Contribution.count

    login_as(:john)
    post :create, :contribution => { }

    assert_equal old_count+1, Contribution.count
    assert_redirected_to contribution_path(assigns(:contribution))
  end

  # not used on site
  def test_should_show_contribution
    #login_as(:john)
    #get :show, :id => 1
    #assert_response :success
    
    assert true
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_contribution
    login_as(:john)
    put :update, :id => 1, :contribution => { }
    assert_redirected_to contribution_path(assigns(:contribution))
  end
  
  def test_should_destroy_contribution
    old_count = Contribution.count

    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Contribution.count
    assert_redirected_to contributions_path
  end
end
