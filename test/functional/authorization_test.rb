# myExperiment: test/functional/authorization_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'

# Re-raise errors caught by the controller.
class WorkflowsController; def rescue_action(e) raise e end; end

class AuthorizationTest < Test::Unit::TestCase
  fixtures :workflows, :users, :contributions, :workflow_versions, :content_blobs, :blobs, :packs, :policies, :permissions, :networks, :friendships, :memberships

  def test_truth
    assert true
  end

  def test_is_owner
    assert Authorization.is_owner?(users(:john).id, workflows(:workflow_dilbert).contribution)
  end

  def test_is_not_owner
    assert !Authorization.is_owner?(users(:jane).id, workflows(:workflow_dilbert).contribution)
  end

  def test_is_friend
    assert Authorization.is_friend?(users(:john).id, users(:jane).id)
  end

  def test_is_not_friend
    assert !Authorization.is_friend?(users(:john).id, users(:admin).id)
  end

  def test_is_member_of_group
    assert Authorization.is_network_member?(users(:john).id, networks(:another_network).id)
    assert Authorization.is_network_member?(users(:jane).id, networks(:dilbert_appreciation_network).id)
  end

  def test_is_not_member_of_group
    assert !Authorization.is_network_member?(users(:admin).id, networks(:dilbert_appreciation_network).id)
  end

  def test_is_owner_authorized_to_view
    # "thing" referenced by ID and Type; only user_id, not instance supplied
    assert Authorization.is_authorized?("view", "Blob", blobs(:for_true_policy).id, users(:john).id)
    
    # "thing" referenced by ID and Type; user instance supplied
    assert Authorization.is_authorized?("view", "Blob", blobs(:for_false_policy).id, users(:john))
    
    # "thing" supplied as instance; user instance supplied
    assert Authorization.is_authorized?("view", nil, blobs(:for_protected_policy), users(:john))
    
    # "thing" supplied as instance; only user_id, not instance supplied
    assert Authorization.is_authorized?("view", nil, blobs(:for_public_policy), users(:john).id)
  end

  def test_is_owner_authorized_to_edit
    assert Authorization.is_authorized?("edit", nil, blobs(:for_true_policy), users(:john))
    assert Authorization.is_authorized?("edit", nil, blobs(:for_false_policy), users(:john))
    assert Authorization.is_authorized?("edit", nil, blobs(:for_protected_policy), users(:john))
    assert Authorization.is_authorized?("edit", nil, blobs(:for_public_policy), users(:john))
  end

  def test_is_owner_authorized_to_download
    assert Authorization.is_authorized?("download", nil, blobs(:for_true_policy), users(:john))
    assert Authorization.is_authorized?("download", nil, blobs(:for_false_policy), users(:john))
    assert Authorization.is_authorized?("download", nil, blobs(:for_protected_policy), users(:john))
    assert Authorization.is_authorized?("download", nil, blobs(:for_public_policy), users(:john))
  end

  def test_is_anonymous_authorized_to_view
    # "anonymous" indicated as a default parameter (not even supplied)
    assert Authorization.is_authorized?("view", nil, blobs(:for_true_policy))
    assert !Authorization.is_authorized?("view", nil, blobs(:for_false_policy))
    assert !Authorization.is_authorized?("view", nil, blobs(:for_protected_policy))
    assert Authorization.is_authorized?("view", nil, blobs(:for_public_policy))
    
    # "anonymous" indicated as NIL
    assert Authorization.is_authorized?("view", nil, blobs(:for_true_policy), nil)
    assert !Authorization.is_authorized?("view", nil, blobs(:for_false_policy), nil)
    assert !Authorization.is_authorized?("view", nil, blobs(:for_protected_policy), nil)
    assert Authorization.is_authorized?("view", nil, blobs(:for_public_policy), nil)
    
    # "anonymous" indicated as "0" - the same way as AuthenticadSystem module will
    # do for not logged in users
    assert Authorization.is_authorized?("view", nil, blobs(:for_true_policy), 0)
    assert !Authorization.is_authorized?("view", nil, blobs(:for_false_policy), 0)
    assert !Authorization.is_authorized?("view", nil, blobs(:for_protected_policy), 0)
    assert Authorization.is_authorized?("view", nil, blobs(:for_public_policy), 0)
  end

  def test_is_anonymous_authorized_to_edit
    assert Authorization.is_authorized?("edit", nil, blobs(:for_true_policy), 0)
    assert !Authorization.is_authorized?("edit", nil, blobs(:for_false_policy), 0)
    assert !Authorization.is_authorized?("edit", nil, blobs(:for_protected_policy), 0)
    assert Authorization.is_authorized?("edit", nil, blobs(:for_public_policy), 0)
  end

  def test_is_anonymous_authorized_to_download
    assert Authorization.is_authorized?("download", nil, blobs(:for_true_policy), nil)
    assert !Authorization.is_authorized?("download", nil, blobs(:for_false_policy), nil)
    assert !Authorization.is_authorized?("download", nil, blobs(:for_protected_policy), nil)
    assert Authorization.is_authorized?("download", nil, blobs(:for_public_policy), nil)
  end

  def test_is_friend_authorized_to_view
    assert Authorization.is_authorized?("view", nil, blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.is_authorized?("view", nil, blobs(:for_false_policy), users(:johns_friend))
    assert Authorization.is_authorized?("view", nil, blobs(:for_protected_policy), users(:johns_friend))
    assert Authorization.is_authorized?("view", nil, blobs(:for_public_policy), users(:johns_friend))
  end

  def test_is_friend_authorized_to_edit
    assert Authorization.is_authorized?("edit", nil, blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.is_authorized?("edit", nil, blobs(:for_false_policy), users(:johns_friend))
    assert Authorization.is_authorized?("edit", nil, blobs(:for_protected_policy), users(:johns_friend))
    assert Authorization.is_authorized?("edit", nil, blobs(:for_public_policy), users(:johns_friend))
  end

  def test_is_friend_authorized_to_download
    assert Authorization.is_authorized?("download", nil, blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.is_authorized?("download", nil, blobs(:for_false_policy), users(:johns_friend))
    assert Authorization.is_authorized?("download", nil, blobs(:for_protected_policy), users(:johns_friend))
    assert Authorization.is_authorized?("download", nil, blobs(:for_public_policy), users(:johns_friend))
  end

  def test_is_group_authorized_to_view
    assert Authorization.is_authorized?("view", nil, blobs(:for_true_policy), users(:spare_user))
    assert !Authorization.is_authorized?("view", nil, blobs(:for_false_policy), users(:spare_user))
    assert !Authorization.is_authorized?("view", nil, blobs(:for_protected_policy), users(:spare_user))
    assert Authorization.is_authorized?("view", nil, blobs(:for_public_policy), users(:spare_user))
  end

  def test_is_group_authorized_to_edit
    assert Authorization.is_authorized?("edit", nil, blobs(:for_true_policy), users(:spare_user))
    assert !Authorization.is_authorized?("edit", nil, blobs(:for_false_policy), users(:spare_user))
    assert !Authorization.is_authorized?("edit", nil, blobs(:for_protected_policy), users(:spare_user))
    assert Authorization.is_authorized?("edit", nil, blobs(:for_public_policy), users(:spare_user))
  end

  def test_is_group_authorized_to_download
    assert Authorization.is_authorized?("download", nil, blobs(:for_true_policy), users(:spare_user))
    assert !Authorization.is_authorized?("download", nil, blobs(:for_false_policy), users(:spare_user))
    assert !Authorization.is_authorized?("download", nil, blobs(:for_protected_policy), users(:spare_user))
    assert Authorization.is_authorized?("download", nil, blobs(:for_public_policy), users(:spare_user))
  end

  def test_user_permissions
    assert Authorization.is_authorized?("view", nil, blobs(:for_false_policy), users(:admin))
    assert !Authorization.is_authorized?("edit", nil, blobs(:for_false_policy), users(:admin))
    assert Authorization.is_authorized?("download", nil, blobs(:for_false_policy), users(:admin))
  end

  def test_group_permissions
    assert Authorization.is_authorized?("view", nil, blobs(:for_false_policy), users(:jane))
    assert Authorization.is_authorized?("edit", nil, blobs(:for_false_policy), users(:jane))
    
    # in the fixture "view"/"edit" flags are set to TRUE, but "download" is set to FALSE;
    # cascading permissions should provide permission to download in this case
    assert Authorization.is_authorized?("download", nil, blobs(:for_false_policy), users(:jane))
  end

  def test_is_authorized_to_destroy
    assert Authorization.is_authorized?("destroy", nil, blobs(:for_true_policy), users(:john))
    assert !Authorization.is_authorized?("destroy", nil, blobs(:for_true_policy), users(:jane))
    assert !Authorization.is_authorized?("destroy", nil, blobs(:for_true_policy), users(:admin))
    assert !Authorization.is_authorized?("destroy", nil, blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.is_authorized?("destroy", nil, blobs(:for_true_policy), users(:spare_user))
  end
end
