# myExperiment: test/functional/relationships_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'relationships_controller'

# Re-raise errors caught by the controller.
class RelationshipsController; def rescue_action(e) raise e end; end

class RelationshipsControllerTest < Test::Unit::TestCase
  fixtures :relationships

  def setup
    @controller = RelationshipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:relationships)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_relationship
    old_count = Relationship.count
    post :create, :relationship => { }
    assert_equal old_count+1, Relationship.count
    
    assert_redirected_to relationship_path(assigns(:relationship))
  end

  def test_should_show_relationship
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_relationship
    put :update, :id => 1, :relationship => { }
    assert_redirected_to relationship_path(assigns(:relationship))
  end
  
  def test_should_destroy_relationship
    old_count = Relationship.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Relationship.count
    
    assert_redirected_to relationships_path
  end
end
