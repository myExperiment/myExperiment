# myExperiment: test/functional/users_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

class UsersControllerTest < ActionController::TestCase
  fixtures :users, :profiles

  def test_should_get_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_user
    assert_difference('User.count', 1) do
      post :create, :terms_consent => '1', :user => { :name => "John Doe", :unconfirmed_email => 'test@example.com', :username => 'new_user', :password => 'secret', :password_confirmation => 'secret' }
    end

    assert_redirected_to :action => :index
  end

  def test_should_not_create_user_without_consent
    assert_no_difference('User.count') do
      post :create, :user => { :name => "John Doe", :unconfirmed_email => 'test@example.com', :username => 'new_user', :password => 'secret', :password_confirmation => 'secret' }
    end

    assert assigns(:user).errors[:base]
  end

  def test_should_show_user
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1

    assert_response :success
  end
  
  def test_should_update_user
    login_as(:john)
    put :update, :id => 1, :user => { :name => 'John Smith the third' }

    #assert_response :success
    assigns(:user)
    assert_redirected_to :action => :edit
    #assert_equal "You have successfully updated your display name", flash[:notice]
  end
  
  def test_should_destroy_user
    login_as(:john)
    delete :destroy, :id => 1

    assert_redirected_to :action => :index
    assert_equal "You do not have permission to delete this user.", flash[:notice]
  end
end
