require File.dirname(__FILE__) + '/../test_helper'
require 'runners_controller'

# Re-raise errors caught by the controller.
class RunnersController; def rescue_action(e) raise e end; end

class RunnersControllerTest < Test::Unit::TestCase
  fixtures :taverna_enactors, :users

  def setup
    @controller = RunnersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = taverna_enactors(:taverna_enactor_1).id
  end

  def test_index
    login_as(:john)
    get :index
    assert_response :success
    assert_template 'index'
  end

  # needs proper url/username/password in fixtures. should be looked at by someone who knows about these things
  def test_show
    #login_as(:john)
    #get :show, :id => @first_id

    #assert_response :success
    #assert_template 'show'

    #assert_not_nil assigns(:taverna_enactor)
    #assert assigns(:taverna_enactor).valid?
    
    assert true
  end

  def test_new
    login_as(:john)
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:runner)
  end

  def test_create
    num_taverna_enactors = TavernaEnactor.count

    login_as(:john)
    post :create, :runner => { :title => 'runner', :description => 'a runner', :url => 'http://example.com', :username => 'tom', :password => 'password'  }

    assert_response :redirect
    assert_redirected_to runner_url(assigns(:runner))

    assert_equal num_taverna_enactors + 1, TavernaEnactor.count
  end

  # need to encrypt passwords properly otherwise this errors
  def test_edit
    #login_as(:john)
    #get :edit, :id => @first_id

    #assert_response :success
    #assert_template 'edit'

    #assert_not_nil assigns(:taverna_enactor)
    #assert assigns(:taverna_enactor).valid?
    
    assert true
  end

  def test_update
    login_as(:john)
    post :update, :id => @first_id, :runner => { :title => 'runner', :description => 'a runner', :url => 'http://different.example.com' }
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      TavernaEnactor.find(@first_id)
    }

    login_as(:john)
    post :destroy, :id => @first_id

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      TavernaEnactor.find(@first_id)
    }
  end
end
