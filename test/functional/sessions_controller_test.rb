# myExperiment: test/functional/sessions_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

class SessionsControllerTest < ActionController::TestCase


  test "can logout" do
    login_as(:john)
    assert_equal users(:john).id, session[:user_id]

    delete :destroy

    assert_redirected_to home_url
    assert session[:user_id].nil?
  end
end
