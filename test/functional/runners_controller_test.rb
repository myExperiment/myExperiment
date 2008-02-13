require File.dirname(__FILE__) + '/../test_helper'
require 'runners_controller'

# Re-raise errors caught by the controller.
class RunnersController; def rescue_action(e) raise e end; end

class RunnersControllerTest < Test::Unit::TestCase
  fixtures :taverna_enactors

  def setup
    @controller = RunnersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = taverna_enactors(:first).id
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

    assert_not_nil assigns(:taverna_enactors)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:taverna_enactor)
    assert assigns(:taverna_enactor).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:taverna_enactor)
  end

  def test_create
    num_taverna_enactors = TavernaEnactor.count

    post :create, :taverna_enactor => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_taverna_enactors + 1, TavernaEnactor.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:taverna_enactor)
    assert assigns(:taverna_enactor).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      TavernaEnactor.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      TavernaEnactor.find(@first_id)
    }
  end
end
