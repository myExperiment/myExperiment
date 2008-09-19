require File.dirname(__FILE__) + '/../test_helper'
require 'group_announcements_controller'

# Re-raise errors caught by the controller.
class GroupAnnouncementsController; def rescue_action(e) raise e end; end

class GroupAnnouncementsControllerTest < Test::Unit::TestCase
  fixtures :group_announcements, :networks, :users

  def setup
    @controller = GroupAnnouncementsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index, :group_id => networks(:dilbert_appreciation_network).id
    assert_response :success
  end

  def test_should_get_new
    login_as(:john)
    get :new, :group_id => networks(:dilbert_appreciation_network).id
    assert assigns(:announcement)
    assert_response :success
  end
  
  def test_should_create_group_announcement
    old_count = GroupAnnouncement.count

    login_as(:john)
    post :create, :group_id => networks(:dilbert_appreciation_network).id, :announcement => { :title => 'MyAnnouncement', :body => 'Announcement body', :public => '1' }

    assert_equal old_count+1, GroupAnnouncement.count
    assert assigns(:announcement)
    assert_redirected_to group_announcements_path(networks(:dilbert_appreciation_network).id)
  end

  def test_should_show_group_announcement
    get :show, :group_id => networks(:dilbert_appreciation_network).id, :id => group_announcements(:dilbert_network_public_announcement).id
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :group_id => networks(:dilbert_appreciation_network).id, :id => 1
    assert_response :success
  end
  
  def test_should_update_group_announcement
    login_as(:john)
    put :update, :group_id => networks(:dilbert_appreciation_network).id, :id => 1, :announcement => { :title => 'MyNewTitle' }
    assert_redirected_to group_announcement_path(networks(:dilbert_appreciation_network).id, assigns(:announcement))
  end
  
  def test_should_destroy_group_announcement
    old_count = GroupAnnouncement.count

    login_as(:john)
    delete :destroy, :group_id => networks(:dilbert_appreciation_network).id, :id => 1

    assert_equal old_count-1, GroupAnnouncement.count
    assert_redirected_to group_announcements_path(networks(:dilbert_appreciation_network).id)
  end
end
