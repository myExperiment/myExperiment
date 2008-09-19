# myExperiment: test/functional/authorization_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'
include IsAuthorized

# Re-raise errors caught by the controller.
class WorkflowsController; def rescue_action(e) raise e end; end

class AuthorizationTest < Test::Unit::TestCase
  fixtures :workflows, :users, :contributions, :workflow_versions, :content_blobs, :blobs, :packs, :policies, :permissions, :networks, :friendships, :memberships

  def test_truth
    assert true
  end

  def test_is_owner
    assert is_owner?(workflows(:workflow_dilbert).id, 'Workflow', users(:john).id)
  end

  def test_is_not_owner
    assert !is_owner?(workflows(:workflow_dilbert).id, 'Workflow', users(:jane).id)
  end

  def test_is_friend
    assert is_friend?(users(:john).id, users(:jane).id)
  end

  def test_is_not_friend
    assert !is_friend?(users(:john).id, users(:admin).id)
  end

  def test_is_member_of_group
    assert is_member_of_group?(users(:john).id, networks(:dilbert_appreciation_network).id)
    assert is_member_of_group?(users(:jane).id, networks(:dilbert_appreciation_network).id)
  end

  def test_is_not_member_of_group
    assert !is_member_of_group?(users(:admin).id, networks(:dilbert_appreciation_network).id)
  end

  def test_is_owner_authorized_to_view
    assert is_authorized_to_view?(blobs(:for_true_policy).id, 'Blob', users(:john))
    assert is_authorized_to_view?(blobs(:for_false_policy).id, 'Blob', users(:john))
    assert is_authorized_to_view?(blobs(:for_protected_policy).id, 'Blob', users(:john))
    assert is_authorized_to_view?(blobs(:for_public_policy).id, 'Blob', users(:john))
  end

  def test_is_owner_authorized_to_edit
    assert is_authorized_to_edit?(blobs(:for_true_policy).id, 'Blob', users(:john))
    assert is_authorized_to_edit?(blobs(:for_false_policy).id, 'Blob', users(:john))
    assert is_authorized_to_edit?(blobs(:for_protected_policy).id, 'Blob', users(:john))
    assert is_authorized_to_edit?(blobs(:for_public_policy).id, 'Blob', users(:john))
  end

  def test_is_owner_authorized_to_download
    assert is_authorized_to_download?(blobs(:for_true_policy).id, 'Blob', users(:john))
    assert is_authorized_to_download?(blobs(:for_false_policy).id, 'Blob', users(:john))
    assert is_authorized_to_download?(blobs(:for_protected_policy).id, 'Blob', users(:john))
    assert is_authorized_to_download?(blobs(:for_public_policy).id, 'Blob', users(:john))
  end

  def test_is_anonymous_authorized_to_view
    assert is_authorized_to_view?(blobs(:for_true_policy).id, 'Blob')
    assert !is_authorized_to_view?(blobs(:for_false_policy).id, 'Blob')
    assert !is_authorized_to_view?(blobs(:for_protected_policy).id, 'Blob')
    assert is_authorized_to_view?(blobs(:for_public_policy).id, 'Blob')

    assert is_authorized_to_view?(blobs(:for_true_policy).id, 'Blob', nil)
    assert !is_authorized_to_view?(blobs(:for_false_policy).id, 'Blob', nil)
    assert !is_authorized_to_view?(blobs(:for_protected_policy).id, 'Blob', nil)
    assert is_authorized_to_view?(blobs(:for_public_policy).id, 'Blob', nil)
  end

  def test_is_anonymous_authorized_to_edit
    assert is_authorized_to_edit?(blobs(:for_true_policy).id, 'Blob')
    assert !is_authorized_to_edit?(blobs(:for_false_policy).id, 'Blob')
    assert !is_authorized_to_edit?(blobs(:for_protected_policy).id, 'Blob')
    assert is_authorized_to_edit?(blobs(:for_public_policy).id, 'Blob')
  end

  def test_is_anonymous_authorized_to_download
    assert is_authorized_to_download?(blobs(:for_true_policy).id, 'Blob')
    assert !is_authorized_to_download?(blobs(:for_false_policy).id, 'Blob')
    assert !is_authorized_to_download?(blobs(:for_protected_policy).id, 'Blob')
    assert is_authorized_to_download?(blobs(:for_public_policy).id, 'Blob')
  end

  def test_is_friend_authorized_to_view
    assert is_authorized_to_view?(blobs(:for_true_policy).id, 'Blob', users(:johns_friend))
    assert !is_authorized_to_view?(blobs(:for_false_policy).id, 'Blob', users(:johns_friend))
    assert is_authorized_to_view?(blobs(:for_protected_policy).id, 'Blob', users(:johns_friend))
    assert is_authorized_to_view?(blobs(:for_public_policy).id, 'Blob', users(:johns_friend))
  end

  def test_is_friend_authorized_to_edit
    assert is_authorized_to_edit?(blobs(:for_true_policy).id, 'Blob', users(:johns_friend))
    assert !is_authorized_to_edit?(blobs(:for_false_policy).id, 'Blob', users(:johns_friend))
    assert is_authorized_to_edit?(blobs(:for_protected_policy).id, 'Blob', users(:johns_friend))
    assert is_authorized_to_edit?(blobs(:for_public_policy).id, 'Blob', users(:johns_friend))
  end

  def test_is_friend_authorized_to_download
    assert is_authorized_to_download?(blobs(:for_true_policy).id, 'Blob', users(:johns_friend))
    assert !is_authorized_to_download?(blobs(:for_false_policy).id, 'Blob', users(:johns_friend))
    assert is_authorized_to_download?(blobs(:for_protected_policy).id, 'Blob', users(:johns_friend))
    assert is_authorized_to_download?(blobs(:for_public_policy).id, 'Blob', users(:johns_friend))
  end

  def test_is_group_authorized_to_view
    assert is_authorized_to_view?(blobs(:for_true_policy).id, 'Blob', users(:spare_user))
    assert !is_authorized_to_view?(blobs(:for_false_policy).id, 'Blob', users(:spare_user))
    assert !is_authorized_to_view?(blobs(:for_protected_policy).id, 'Blob', users(:spare_user))
    assert is_authorized_to_view?(blobs(:for_public_policy).id, 'Blob', users(:spare_user))
  end

  def test_is_group_authorized_to_edit
    assert is_authorized_to_edit?(blobs(:for_true_policy).id, 'Blob', users(:spare_user))
    assert !is_authorized_to_edit?(blobs(:for_false_policy).id, 'Blob', users(:spare_user))
    assert !is_authorized_to_edit?(blobs(:for_protected_policy).id, 'Blob', users(:spare_user))
    assert is_authorized_to_edit?(blobs(:for_public_policy).id, 'Blob', users(:spare_user))
  end

  def test_is_group_authorized_to_download
    assert is_authorized_to_download?(blobs(:for_true_policy).id, 'Blob', users(:spare_user))
    assert !is_authorized_to_download?(blobs(:for_false_policy).id, 'Blob', users(:spare_user))
    assert !is_authorized_to_download?(blobs(:for_protected_policy).id, 'Blob', users(:spare_user))
    assert is_authorized_to_download?(blobs(:for_public_policy).id, 'Blob', users(:spare_user))
  end

  def test_user_permissions
    assert is_authorized_to_view?(blobs(:for_false_policy).id, 'Blob', users(:admin))
    assert !is_authorized_to_edit?(blobs(:for_false_policy).id, 'Blob', users(:admin))
    assert is_authorized_to_download?(blobs(:for_false_policy).id, 'Blob', users(:admin))
  end

  def test_group_permissions
    assert is_authorized_to_view?(blobs(:for_false_policy).id, 'Blob', users(:jane))
    assert is_authorized_to_edit?(blobs(:for_false_policy).id, 'Blob', users(:jane))
    assert !is_authorized_to_download?(blobs(:for_false_policy).id, 'Blob', users(:jane))
  end

  def test_is_authorized_to_destroy
    assert is_authorized_to_destroy?(blobs(:for_true_policy).id, 'Blob', users(:john))
    assert !is_authorized_to_destroy?(blobs(:for_true_policy).id, 'Blob', users(:jane))
    assert !is_authorized_to_destroy?(blobs(:for_true_policy).id, 'Blob', users(:admin))
    assert !is_authorized_to_destroy?(blobs(:for_true_policy).id, 'Blob', users(:johns_friend))
    assert !is_authorized_to_destroy?(blobs(:for_true_policy).id, 'Blob', users(:spare_user))
  end
end
