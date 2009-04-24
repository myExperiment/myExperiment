require File.dirname(__FILE__) + '/../test_helper'
require 'reviews_controller'

# Re-raise errors caught by the controller.
class ReviewsController; def rescue_action(e) raise e end; end

class ReviewsControllerTest < Test::Unit::TestCase
  fixtures :reviews, :users, :workflows, :workflow_versions, :contributions, :blobs, :packs, :policies, :permissions, :content_types

  def setup
    @controller = ReviewsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = reviews(:dilbert_review).id
  end

  def test_index
    login_as(:john)
    get :index, :workflow_id => reviews(:dilbert_review).reviewable_id
    assert_response :success
    assert_template 'index'
  end

  def test_show
    login_as(:john)
    get :show, :id => @first_id, :workflow_id => reviews(:dilbert_review).reviewable_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:review)
    assert assigns(:review).valid?
  end

  def test_new
    login_as(:john)
    get :new, :workflow_id => reviews(:dilbert_review).reviewable_id

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:review)
  end

  def test_create
    num_reviews = Review.count

    login_as(:john)
    post :create, :review => { :title => 'my review', :review => 'very good, well done' }, :workflow_id => reviews(:dilbert_review).reviewable_id

    assert_response :redirect
    assert_redirected_to :action => 'show'

    assert_equal num_reviews + 1, Review.count
  end

  def test_edit
    login_as(:jane)
    get :edit, :id => @first_id, :workflow_id => reviews(:dilbert_review).reviewable_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:review)
    assert assigns(:review).valid?
  end

  def test_update
    login_as(:jane)
    post :update, :id => @first_id, :workflow_id => reviews(:dilbert_review).reviewable_id, :review => { :title => 'my updated review' }

    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Review.find(@first_id)
    }

    login_as(:jane)
    post :destroy, :id => @first_id, :workflow_id => reviews(:dilbert_review).reviewable_id

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      Review.find(@first_id)
    }
  end
end
