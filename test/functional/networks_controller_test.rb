##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

require File.dirname(__FILE__) + '/../test_helper'
require 'networks_controller'

# Re-raise errors caught by the controller.
class NetworksController; def rescue_action(e) raise e end; end

class NetworksControllerTest < Test::Unit::TestCase
  fixtures :networks

  def setup
    @controller = NetworksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:networks)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_network
    old_count = Network.count
    post :create, :network => { }
    assert_equal old_count+1, Network.count
    
    assert_redirected_to network_path(assigns(:network))
  end

  def test_should_show_network
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_network
    put :update, :id => 1, :network => { }
    assert_redirected_to network_path(assigns(:network))
  end
  
  def test_should_destroy_network
    old_count = Network.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Network.count
    
    assert_redirected_to networks_path
  end
end
