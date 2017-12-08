# myExperiment: test/functional/networks_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'networks_controller'

class NetworksControllerTest < ActionController::TestCase
  fixtures :networks, :users, :content_types

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
  
  def test_should_create_network
    old_count = Network.count

    login_as(:john)
    post :create, :network => { :title => 'test network', :unique_name => 'test_network', :new_member_policy => 'open', :description => "..." }, :feed_uri => "", :feed_user => "", :feed_pass => ""

    assert_equal old_count+1, Network.count    
    assert_redirected_to network_path(assigns(:network))
  end

  def test_should_show_network
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1

    assert_response :success
  end
  
  def test_should_update_network
    login_as(:john)
    put :update, :id => 1, 
                 :network => { :title => 'test network', :unique_name => 'update_network', :new_member_policy => 'open', :description => ".?."}, :feed_uri => "", :feed_user => "", :feed_pass => ""

    assert_redirected_to network_path(assigns(:network))
  end
  
  def test_should_destroy_network
    old_count = Network.count

    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Network.count   
    assert_redirected_to networks_path
  end

  def test_should_transfer_network_ownership
    login_as(:john)
    other_user = users(:jane)
    put :transfer_ownership, :id => 1, :user_id => other_user.id

    assert_redirected_to network_path(assigns(:network))
    assert_equal other_user.id, assigns(:network).user_id
    assert_includes assigns(:network).members, users(:john)
  end

  def test_should_not_transfer_network_ownership_if_not_admin
    login_as(:jane)
    other_user = users(:jane)
    put :transfer_ownership, :id => 1, :user_id => other_user.id

    assert_response :unauthorized
    assert_not_equal other_user.id, assigns(:network).user_id
  end
end
