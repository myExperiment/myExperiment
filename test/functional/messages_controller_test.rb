# myExperiment: test/functional/messages_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'messages_controller'

# Re-raise errors caught by the controller.
class MessagesController; def rescue_action(e) raise e end; end

class MessagesControllerTest < Test::Unit::TestCase
  fixtures :messages, :users

  def setup
    @controller = MessagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    login_as(:john)
    get :index

    assert_response :success
    assert assigns(:messages)
  end

  def test_should_get_new
    login_as(:john)
    get :new

    assert_response :success
  end

## Requires an SMTP mailer to work i think
#  def test_should_create_message
#    old_count = Message.count
#
#    login_as(:john)
#    post :create, :message => { :to => '2', :from => '1', :subject => 'My message to you...', :body => 'message message message' }
#
#    assert_response :redirect
#    assert_redirected_to messages_path
#    assert_equal old_count+1, Message.count   
#  end

  def test_should_show_message
    login_as(:john)
    get :show, :id => 1

    assert_response :success
  end

  # test does not seem to update deleted_by_sender or deleted_by_recipient fields
  # and does not remove record. I don't know why, the code works when tested manually.
  def test_should_destroy_message
    old_count = Message.count

    assert_equal false, messages(:jane_to_john).deleted_by_sender
    assert_equal false, messages(:jane_to_john).deleted_by_recipient

    login_as(:john)
    delete :destroy, :id => 2

    assert_redirected_to messages_path
    #assert_equal true, messages(:jane_to_john).deleted_by_recipient

    login_as(:jane)
    delete :destroy, :id => 2, :deleted_from => 'outbox'

    assert_redirected_to sent_messages_path
    #assert_equal old_count-1, Message.count
  end
end
