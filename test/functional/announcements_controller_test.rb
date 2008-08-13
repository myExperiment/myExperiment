require File.dirname(__FILE__) + '/../test_helper'
require 'announcements_controller'

# Re-raise errors caught by the controller.
class AnnouncementsController; def rescue_action(e) raise e end; end

class AnnouncementsControllerTest < Test::Unit::TestCase
  fixtures :announcements
  fixtures :users

  def setup
    @controller = AnnouncementsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = announcements(:first_announcement).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:announcement)
    assert assigns(:announcement).valid?
  end

  def test_new_with_no_login
    get :new

    assert_response :redirect
    assert_equal "Only administrators have access to create, update and delete announcements.", flash[:error]

    follow_redirect
    assert_response :success
    assert_template 'index'
  end

  def test_new_with_user_login
    login_as(:jane)
    get :new

    assert_response :redirect
    assert_equal "Only administrators have access to create, update and delete announcements.", flash[:error]

    follow_redirect
    assert_response :success
    assert_template 'index'
  end

  def test_new_with_admin_login
    login_as(:admin)
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:announcement)
  end

  def test_create
    num_announcements = Announcement.count

    login_as(:admin)
    post :create, :announcement => { :title => "Test announcement", :body => "test test test test" }#, :body_html => "test test test test" }

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_equal num_announcements + 1, Announcement.count
  end

  def test_edit
    login_as(:admin)
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:announcement)
    assert assigns(:announcement).valid?
  end

  def test_update
    login_as(:admin)
    post :update, :id => @first_id, :announcement => { :title => 'Updated announcement', :body => 'update update' }
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Announcement.find(@first_id)
    }

    login_as(:admin)
    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      Announcement.find(@first_id)
    }
  end
end
