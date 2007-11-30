# myExperiment: test/functional/contributions_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'contributions_controller'

# Re-raise errors caught by the controller.
class ContributionsController; def rescue_action(e) raise e end; end

class ContributionsControllerTest < Test::Unit::TestCase
  fixtures :contributions

  def setup
    @controller = ContributionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:contributions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_contribution
    old_count = Contribution.count
    post :create, :contribution => { }
    assert_equal old_count+1, Contribution.count
    
    assert_redirected_to contribution_path(assigns(:contribution))
  end

  def test_should_show_contribution
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_contribution
    put :update, :id => 1, :contribution => { }
    assert_redirected_to contribution_path(assigns(:contribution))
  end
  
  def test_should_destroy_contribution
    old_count = Contribution.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Contribution.count
    
    assert_redirected_to contributions_path
  end
end
