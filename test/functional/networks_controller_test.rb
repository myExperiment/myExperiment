# myExperiment: test/functional/networks_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'networks_controller'

# Re-raise errors caught by the controller.
class NetworksController; def rescue_action(e) raise e end; end

class NetworksControllerTest < Test::Unit::TestCase
  fixtures :networks, :users, :content_types

  def setup
    @controller = NetworksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

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
    post :create, :network => { :user_id => '990', :title => 'test network', :unique_name => 'test_network', :auto_accept => '0', :description => "..." }

    assert_equal old_count+1, Network.count    
    assert_redirected_to group_path(assigns(:network))
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
                 :network => { :user_id => '990', :title => 'test network', :unique_name => 'update_network', :auto_accept => '0', :description => ".?."}

    assert_redirected_to group_path(assigns(:network))
  end
  
  def test_should_destroy_network
    old_count = Network.count

    login_as(:john)
    delete :destroy, :id => 1

    assert_equal old_count-1, Network.count   
    assert_redirected_to groups_path
  end
end
