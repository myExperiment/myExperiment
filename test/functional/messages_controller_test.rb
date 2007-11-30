# myExperiment: test/functional/messages_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'messages_controller'

# Re-raise errors caught by the controller.
class MessagesController; def rescue_action(e) raise e end; end

class MessagesControllerTest < Test::Unit::TestCase
  fixtures :messages

  def setup
    @controller = MessagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:messages)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_message
    old_count = Message.count
    post :create, :message => { }
    assert_equal old_count+1, Message.count
    
    assert_redirected_to message_path(assigns(:message))
  end

  def test_should_show_message
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_message
    put :update, :id => 1, :message => { }
    assert_redirected_to message_path(assigns(:message))
  end
  
  def test_should_destroy_message
    old_count = Message.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Message.count
    
    assert_redirected_to messages_path
  end
end
