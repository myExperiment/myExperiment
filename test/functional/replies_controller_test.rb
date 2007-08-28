require File.dirname(__FILE__) + '/../test_helper'
require 'replies_controller'

# Re-raise errors caught by the controller.
class RepliesController; def rescue_action(e) raise e end; end

class RepliesControllerTest < Test::Unit::TestCase
  fixtures :replies

  def setup
    @controller = RepliesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = replies(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:replies)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:reply)
    assert assigns(:reply).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:reply)
  end

  def test_create
    num_replies = Reply.count

    post :create, :reply => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_replies + 1, Reply.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:reply)
    assert assigns(:reply).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Reply.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Reply.find(@first_id)
    }
  end
end
