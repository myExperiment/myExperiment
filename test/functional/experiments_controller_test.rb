require File.dirname(__FILE__) + '/../test_helper'
require 'experiments_controller'

# Re-raise errors caught by the controller.
class ExperimentsController; def rescue_action(e) raise e end; end

class ExperimentsControllerTest < Test::Unit::TestCase
  fixtures :experiments

  def setup
    @controller = ExperimentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = experiments(:first).id
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

    assert_not_nil assigns(:experiments)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:experiment)
    assert assigns(:experiment).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:experiment)
  end

  def test_create
    num_experiments = Experiment.count

    post :create, :experiment => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_experiments + 1, Experiment.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:experiment)
    assert assigns(:experiment).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Experiment.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Experiment.find(@first_id)
    }
  end
end
