require File.dirname(__FILE__) + '/../test_helper'
require 'citations_controller'

# Re-raise errors caught by the controller.
class CitationsController; def rescue_action(e) raise e end; end

class CitationsControllerTest < Test::Unit::TestCase
  fixtures :citations, :workflows, :workflow_versions, :content_blobs, :users, :contributions, :blobs, :packs, :policies, :permissions

  def setup
    @controller = CitationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    login_as(:john)
    get :index, :workflow_id => '1'

    assert_response :success
    assert assigns(:citations)
  end

  def test_should_get_new
    login_as(:john)
    get :new, :workflow_id => '1'

    assert_response :success
  end
  
  def test_should_create_citation
    old_count = Citation.count

    login_as(:john)
    post :create, :workflow_id => '1', 
                  :citation => { :user_id => '1', 
                                 :workflow_id => '1', 
                                 :workflow_version => '1', 
                                 :title => 'Citation', 
                                 :authors => 'John and Jane', 
                                 :published_at => '2008-08-08' }

    assert_redirected_to workflow_citation_url(assigns(:workflow), assigns(:citation))
    assert_equal old_count+1, Citation.count
  end

  def test_should_show_citation
    get :show, :id => 1, :workflow_id => '1'
    assert_response :success
  end

  def test_should_get_edit
    login_as(:john)
    get :edit, :id => 1, :workflow_id => '1'
    assert_response :success
  end
  
  def test_should_update_citation
    login_as(:john)
    put :update, :id => 1, :workflow_id => '1', :citation => { :user_id => '1', 
                                                               :workflow_id => '1', 
                                                               :workflow_version => '1', 
                                                               :title => 'Edited Citation', 
                                                               :authors => 'John and Jane and jim', 
                                                               :published_at => '2008-08-08' }

    assert "Citation was successfully updated.", flash[:notice]
    assert_response :success
  end
  
  def test_should_destroy_citation
    old_count = Citation.count

    login_as(:john)
    delete :destroy, :id => 1, :workflow_id => '1'

    assert_equal old_count-1, Citation.count    
    assert_redirected_to workflow_citations_path(assigns(:workflow))
  end

end
