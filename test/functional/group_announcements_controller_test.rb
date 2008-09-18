require File.dirname(__FILE__) + '/../test_helper'
require 'group_announcements_controller'

# Re-raise errors caught by the controller.
class GroupAnnouncementsController; def rescue_action(e) raise e end; end

class GroupAnnouncementsControllerTest < Test::Unit::TestCase
  fixtures :group_announcements

  def setup
    @controller = GroupAnnouncementsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:group_announcements)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_group_announcement
    old_count = GroupAnnouncement.count
    post :create, :group_announcement => { }
    assert_equal old_count+1, GroupAnnouncement.count
    
    assert_redirected_to group_announcement_path(assigns(:group_announcement))
  end

  def test_should_show_group_announcement
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_group_announcement
    put :update, :id => 1, :group_announcement => { }
    assert_redirected_to group_announcement_path(assigns(:group_announcement))
  end
  
  def test_should_destroy_group_announcement
    old_count = GroupAnnouncement.count
    delete :destroy, :id => 1
    assert_equal old_count-1, GroupAnnouncement.count
    
    assert_redirected_to group_announcements_path
  end
end
