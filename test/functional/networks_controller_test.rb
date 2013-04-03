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
    post :create, :network => { :title => 'test network', :unique_name => 'test_network', :new_member_policy => 'open', :description => "..." }

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
                 :network => { :title => 'test network', :unique_name => 'update_network', :new_member_policy => 'open', :description => ".?."}

    assert_redirected_to network_path(assigns(:network))
  end
  
  def test_should_destroy_network
    old_count = Network.count

    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Network.count   
    assert_redirected_to networks_path
  end
end
