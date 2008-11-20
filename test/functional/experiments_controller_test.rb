require File.dirname(__FILE__) + '/../test_helper'
require 'experiments_controller'

# Re-raise errors caught by the controller.
class ExperimentsController; def rescue_action(e) raise e end; end

class ExperimentsControllerTest < Test::Unit::TestCase
  fixtures :experiments, :users

  def setup
    @controller = ExperimentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = experiments(:experiment_1).id
  end

  def test_index
    login_as(:john)
    get :index

    assert_response :success
    assert_template 'index'
  end

#  def test_list
#    get :list
#
#    assert_response :success
#    assert_template 'list'
#
#    assert_not_nil assigns(:experiments)
#  end

  def test_show
    login_as(:john)
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:experiment)
    assert assigns(:experiment).valid?
  end

  def test_new
    login_as(:john)
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:experiment)
  end

  def test_create
    login_as(:john)
    num_experiments = Experiment.count

    post :create, :experiment => { :title => 'myExperiment', :description => 'just a test' }

    assert_redirected_to experiment_url(assigns(:experiment))

    assert_equal num_experiments + 1, Experiment.count
  end

  def test_edit
    login_as(:john)
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:experiment)
    assert assigns(:experiment).valid?
  end

  def test_update
    login_as(:john)
    post :update, :id => @first_id, :experiment => { :title => 'myExperiment updated' }

    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Experiment.find(@first_id)
    }

    login_as(:john)
    post :destroy, :id => @first_id

    assert_redirected_to experiments_url

    assert_raise(ActiveRecord::RecordNotFound) {
      Experiment.find(@first_id)
    }
  end
end
