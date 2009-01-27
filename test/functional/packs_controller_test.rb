require File.dirname(__FILE__) + '/../test_helper'
require 'packs_controller'

# Re-raise errors caught by the controller.
class PacksController; def rescue_action(e) raise e end; end

class PacksControllerTest < Test::Unit::TestCase
  fixtures :packs, :users, :contributions, :workflows, :blobs, :content_blobs, :policies, :permissions, :networks
  
  def setup
    @controller = PacksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = packs(:pack_1).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_show
    login_as(:john)
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:pack)
    assert assigns(:pack).valid?
  end

  def test_new
    login_as(:john)
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:pack)
  end

  def test_create
    num_packs = Pack.count

    login_as(:john)
    post :create, :pack => { :title => 'my new pack', :description => 'a new pack lalalala' }

    assert_response :redirect
    assert_redirected_to(pack_url(assigns(:pack)))

    assert_equal num_packs + 1, Pack.count
  end

  def test_edit
    login_as(:john)
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:pack)
    assert assigns(:pack).valid?
  end

  def test_update
    login_as(:john)
    post :update, :id => @first_id, :pack => { :title => 'edited pack', :description => 'a new pack' }

    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Pack.find(@first_id)
    }

    login_as(:john)
    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      Pack.find(@first_id)
    }
  end
end
