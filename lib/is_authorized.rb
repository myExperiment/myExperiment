module IsAuthorized

  # check the relevant permissions based on 'action' string
  def is_authorized?(action, contributable_id, contributable_type, user=nil)
    is_authorized = false

    case action
    when 'show', 'index', 'search', 'favourite', 'favourite_delete', 'comment', 'comment_delete', 'rate', 'tag', 'view', 'comments_timeline', 'comments', 'items'
      is_authorized = is_authorized_to_view?(contributable_id, contributable_type, user)
    when 'edit', 'new', 'create', 'update', 'new_version', 'create_version', 'destroy_version', 'edit_version', 'update_version', 'new_item', 'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link'
      is_authorized = is_authorized_to_edit?(contributable_id, contributable_type, user)
    when 'download', 'named_download', 'submit_job', 'launch'
      is_authorized = is_authorized_to_download?(contributable_id, contributable_type, user)
    when 'destroy', 'destroy_item'
      is_authorized = is_authorized_to_destroy?(contributable_id, contributable_type, user)
    end

    is_authorized
  end

  # check if current user is authorized to view contribution
  def is_authorized_to_view?(contributable_id, contributable_type, user=nil)
    is_authorized = false
    
    if !user.nil? && user.kind_of?(User)
      user_id = user.id
    else
      user_id = 0
    end

    # check if current user owns contributable
    if user_id != 0
      is_authorized = is_owner?(contributable_id, contributable_type, user_id)
    end

    # if current user is not owner then check policy to determine if user is authorized
    if !is_authorized
      is_authorized = check_policy('view', contributable_id, contributable_type, user_id)
    end

    is_authorized
  end

  # check if current user is authorized to edit contribution
  def is_authorized_to_edit?(contributable_id, contributable_type, user=nil)
    is_authorized = false

    if !user.nil? && user.kind_of?(User)
      user_id = user.id
    else
      user_id = 0
    end

    # check if current user owns contributable
    if user_id != 0
      is_authorized = is_owner?(contributable_id, contributable_type, user_id)
    end

    # if current user is not owner then check policy to determine if user is authorized
    if !is_authorized
      is_authorized = check_policy('edit', contributable_id, contributable_type, user_id)
    end

    is_authorized
  end

  # check if current user is authorized to download the contribution
  def is_authorized_to_download?(contributable_id, contributable_type, user=nil)
    is_authorized = false

    if !user.nil? && user.kind_of?(User)
      user_id = user.id
    else
      user_id = 0
    end

    # check if current user owns contributable
    if user_id != 0
      is_authorized = is_owner?(contributable_id, contributable_type, user_id)
    end

    # if current user is not owner then check policy to determine if user is authorized
    if !is_authorized
      is_authorized = check_policy('download', contributable_id, contributable_type, user_id)
    end
    
    is_authorized
  end

  # check if current user is authorized to destroy the contribution
  def is_authorized_to_destroy?(contributable_id, contributable_type, user=nil)
    is_authorized = false

    # current user can destroy contribution if they own it
    if !user.nil? && user.kind_of?(User)
      is_authorized = is_owner?(contributable_id, contributable_type, user.id)
    end

    is_authorized
  end

  private

  # check if current user is owner of contribution
  def is_owner?(contributable_id, contributable_type, user_id)
    is_authorized = false

    # get owner of contribution from database
    contribution = Contribution.find_by_sql "SELECT contributor_id,contributor_type FROM contributions WHERE contributable_id=\'#{contributable_id}\' AND contributable_type=\'#{contributable_type}\'"

    # if owner of contribution is the current user then the current user is authorized
    if contribution[0]['contributor_type'] == 'User' && contribution[0]['contributor_id'] == user_id
      is_authorized = true
    end

    is_authorized
  end

  # check whether current user is authorized for 'action' on 'contributable_*'
  def check_policy(action, contributable_id, contributable_type, user_id)
    is_authorized = false
    # get relevant part of policy from database
    select_string = 'policies.id,policies.contributor_id,policies.contributor_type,policies.share_mode,policies.update_mode'
    policy_details = get_policy(select_string, contributable_id, contributable_type)
    
    # if there is no policy, only true if user owns contributable
    if policy_details.length == 0
      return is_owner?(contributable_id, contributable_type, user_id)
    end

    ####################################################################################
    #
    # For details on what each sharing mode means, see there wiki here:
    # http://wiki.myexperiment.org/index.php/Developer:Ownership_Sharing_and_Permissions
    #
    ####################################################################################
    share_mode = policy_details[0]['share_mode'].to_i
    update_mode = policy_details[0]['update_mode'].to_i

    case action
    when 'view'
      # if share mode is 0,1,2, anyone can view
      if share_mode == 0 || share_mode == 1 || share_mode == 2
        is_authorized = true
      # if share mode is 3,4, friends can view, or if update mode is 1, friends can view (due to cascading permissions)
      elsif !is_authorized && user_id != 0 && (share_mode == 3 || share_mode == 4 || update_mode == 1)
        is_authorized = is_friend?(policy_details[0]['contributor_id'], user_id)
      end
    when 'download'
      # if share mode is 0, anyone can download
      if share_mode == 0
        is_authorized = true
      # if share mode is 1,3, friends can download, or if update mode is 1, friends can download (due to cascading permissions)
      elsif !is_authorized && user_id != 0 && (share_mode == 1 || share_mode == 3 || update_mode == 1)
        is_authorized = is_friend?(policy_details[0]['contributor_id'], user_id)
      end
    when 'edit'
      # if update mode is 0, anyone with view & download permissions can edit (sharing mode 0 for anonymous)
      if update_mode == 0 && share_mode == 0
        is_authorized == true
      # if update mode is 1, friends can edit, or if update mode is 0 and friends have view & download permissions, they can edit
      elsif update_mode == 1 || (update_mode == 0 && (share_mode == 0 || share_mode == 1 || share_mode == 3))
        is_authorized = is_friend?(policy_details[0]['contributor_id'], user_id)
      end
    end

    # if user not yet authorized, check permissions belonging to the policy
    if !is_authorized && user_id != 0
      is_authorized = check_permissions(policy_details[0]['id'], action, user_id)
    end

    # return is_authorized
    is_authorized
  end

  def check_permissions(policy_id, action, user_id)
    permissions_details = get_permissions(policy_id)

    # check permissions records for matching policy_id and current_user.id and decide if authorized
    permissions_details.each do |permission|
      if permission['contributor_id'] == user_id && permission['contributor_type'] == 'User' && permission["#{action}"]
        return true
      end
    end

    # or check for matching policy_id and a group.id then check if current_user is member of group.id
    permissions_details.each do |permission|
      if permission['contributor_type'] == 'Network' && permission["#{action}"]
        if is_member_of_group? user_id, permission['contributor_id']
          return true
        end
      end
    end

    false
  end

  def is_friend?(contributor_id, user_id)
    friendship = Friendship.find_by_sql "SELECT id FROM friendships WHERE (user_id=#{contributor_id} AND friend_id=#{user_id}) OR (user_id=#{user_id} AND friend_id=#{contributor_id})"

    if friendship.length > 0
      return true
    else
      return false
    end
  end

  def is_member_of_group?(user_id, network_id)
    membership = Membership.find_by_sql "SELECT id FROM memberships WHERE user_id=#{user_id} AND network_id=#{network_id}"

    # check if there is a membership record for user_id and network_id
    if membership.length > 0
      return true
    else
      # if there is no membership record check whether user_id is the owner of network_id
      network = Network.find_by_sql "SELECT user_id FROM networks WHERE user_id=#{user_id} AND id=#{network_id}"
      if network.length > 0
        return true
      else
        return false
      end
    end
  end

  # query database for relevant fields in policies table
  def get_policy(select_string, contributable_id, contributable_type)
    Policy.find_by_sql "SELECT #{select_string} FROM contributions,policies WHERE contributions.policy_id=policies.id AND contributions.contributable_id=#{contributable_id} AND contributions.contributable_type=\'#{contributable_type}\'"
  end

  # get all permissions related to policy
  def get_permissions(policy_id)
    select_string = 'contributor_id,contributor_type,download,edit,view'
    Permission.find_by_sql "SELECT #{select_string} FROM permissions WHERE policy_id=#{policy_id}"
  end

end
