# myExperiment: test/functional/authorization_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'

class AuthorizationTest < ActionController::TestCase
  fixtures :workflows, :users, :contributions, :workflow_versions, :content_blobs, :blobs, :packs, :policies, :permissions, :networks, :friendships, :memberships, :licenses

  def test_truth
    assert true
  end

  def test_is_owner_authorized_to_view
    assert Authorization.check("view", blobs(:for_true_policy), users(:john))
    assert Authorization.check("view", blobs(:for_false_policy), users(:john))
    assert Authorization.check("view", blobs(:for_protected_policy), users(:john))
    assert Authorization.check("view", blobs(:for_public_policy), users(:john))
  end

  def test_is_owner_authorized_to_edit
    assert Authorization.check("edit", blobs(:for_true_policy), users(:john))
    assert Authorization.check("edit", blobs(:for_false_policy), users(:john))
    assert Authorization.check("edit", blobs(:for_protected_policy), users(:john))
    assert Authorization.check("edit", blobs(:for_public_policy), users(:john))
  end

  def test_is_owner_authorized_to_download
    assert Authorization.check("download", blobs(:for_true_policy), users(:john))
    assert Authorization.check("download", blobs(:for_false_policy), users(:john))
    assert Authorization.check("download", blobs(:for_protected_policy), users(:john))
    assert Authorization.check("download", blobs(:for_public_policy), users(:john))
  end

  def test_is_anonymous_authorized_to_view
    
    # "anonymous" indicated as nil
    assert Authorization.check("view", blobs(:for_true_policy), nil)
    assert !Authorization.check("view", blobs(:for_false_policy), nil)
    assert !Authorization.check("view", blobs(:for_protected_policy), nil)
    assert Authorization.check("view", blobs(:for_public_policy), nil)
    
    # "anonymous" indicated as "0" - the same way as AuthenticadSystem module will
    # do for not logged in users
    assert Authorization.check("view", blobs(:for_true_policy), 0)
    assert !Authorization.check("view", blobs(:for_false_policy), 0)
    assert !Authorization.check("view", blobs(:for_protected_policy), 0)
    assert Authorization.check("view", blobs(:for_public_policy), 0)
  end

  def test_is_anonymous_authorized_to_edit
    assert Authorization.check("edit", blobs(:for_true_policy), 0)
    assert !Authorization.check("edit", blobs(:for_false_policy), 0)
    assert !Authorization.check("edit", blobs(:for_protected_policy), 0)
    assert Authorization.check("edit", blobs(:for_public_policy), 0)
  end

  def test_is_anonymous_authorized_to_download
    assert Authorization.check("download", blobs(:for_true_policy), nil)
    assert !Authorization.check("download", blobs(:for_false_policy), nil)
    assert !Authorization.check("download", blobs(:for_protected_policy), nil)
    assert Authorization.check("download", blobs(:for_public_policy), nil)
  end

  def test_is_friend_authorized_to_view
    assert Authorization.check("view", blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.check("view", blobs(:for_false_policy), users(:johns_friend))
    assert Authorization.check("view", blobs(:for_protected_policy), users(:johns_friend))
    assert Authorization.check("view", blobs(:for_public_policy), users(:johns_friend))
  end

  def test_is_friend_authorized_to_edit
    assert Authorization.check("edit", blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.check("edit", blobs(:for_false_policy), users(:johns_friend))
    assert Authorization.check("edit", blobs(:for_protected_policy), users(:johns_friend))
    assert Authorization.check("edit", blobs(:for_public_policy), users(:johns_friend))
  end

  def test_is_friend_authorized_to_download
    assert Authorization.check("download", blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.check("download", blobs(:for_false_policy), users(:johns_friend))
    assert Authorization.check("download", blobs(:for_protected_policy), users(:johns_friend))
    assert Authorization.check("download", blobs(:for_public_policy), users(:johns_friend))
  end

  def test_is_group_authorized_to_view
    assert Authorization.check("view", blobs(:for_true_policy), users(:spare_user))
    assert !Authorization.check("view", blobs(:for_false_policy), users(:spare_user))
    assert !Authorization.check("view", blobs(:for_protected_policy), users(:spare_user))
    assert Authorization.check("view", blobs(:for_public_policy), users(:spare_user))
  end

  def test_is_group_authorized_to_edit
    assert Authorization.check("edit", blobs(:for_true_policy), users(:spare_user))
    assert !Authorization.check("edit", blobs(:for_false_policy), users(:spare_user))
    assert !Authorization.check("edit", blobs(:for_protected_policy), users(:spare_user))
    assert Authorization.check("edit", blobs(:for_public_policy), users(:spare_user))
  end

  def test_is_group_authorized_to_download
    assert Authorization.check("download", blobs(:for_true_policy), users(:spare_user))
    assert !Authorization.check("download", blobs(:for_false_policy), users(:spare_user))
    assert !Authorization.check("download", blobs(:for_protected_policy), users(:spare_user))
    assert Authorization.check("download", blobs(:for_public_policy), users(:spare_user))
  end

  def test_user_permissions
    assert Authorization.check("view", blobs(:for_false_policy), users(:admin))
    assert !Authorization.check("edit", blobs(:for_false_policy), users(:admin))
    assert Authorization.check("download", blobs(:for_false_policy), users(:admin))
  end

  def test_group_permissions
    assert Authorization.check("view", blobs(:for_false_policy), users(:jane))
    assert Authorization.check("edit", blobs(:for_false_policy), users(:jane))
    
    # in the fixture "view"/"edit" flags are set to TRUE, but "download" is set to FALSE;
    # cascading permissions should provide permission to download in this case
    assert Authorization.check("download", blobs(:for_false_policy), users(:jane))
  end

  def test_is_authorized_to_destroy
    assert Authorization.check("destroy", blobs(:for_true_policy), users(:john))
    assert !Authorization.check("destroy", blobs(:for_true_policy), users(:jane))
    assert !Authorization.check("destroy", blobs(:for_true_policy), users(:admin))
    assert !Authorization.check("destroy", blobs(:for_true_policy), users(:johns_friend))
    assert !Authorization.check("destroy", blobs(:for_true_policy), users(:spare_user))
  end
end
