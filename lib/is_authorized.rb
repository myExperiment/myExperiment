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
      is_authorized = is_owner? contributable_id, contributable_type, user_id
    end

    # if current user is not owner then check policy to determine if user is authorized
    if !is_authorized
      is_authorized = check_policy 'view', contributable_id, contributable_type, user_id
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
      is_authorized = is_owner? contributable_id, contributable_type, user_id
    end

    # if current user is not owner then check policy to determine if user is authorized
    if !is_authorized
      is_authorized = check_policy 'edit', contributable_id, contributable_type, user_id
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
      is_authorized = is_owner? contributable_id, contributable_type, user_id
    end

    # if current user is not owner then check policy to determine if user is authorized
    if !is_authorized
      is_authorized = check_policy 'download', contributable_id, contributable_type, user_id
    end
    
    is_authorized
  end

  # check if current user is authorized to destroy the contribution
  def is_authorized_to_destroy?(contributable_id, contributable_type, user=nil)
    is_authorized = false

    # current user can destroy contribution if they own it
    if !user.nil? && user.kind_of?(User)
      is_authorized = is_owner? contributable_id, contributable_type, user.id
    end

    is_authorized
  end

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
    select_string = 'policies.id,policies.contributor_id,policies.contributor_type'
    # set strings based on which fields we are interested in
    public_string = action + '_public'
    #friends_string = action + '_friends'
    friends_string = action + '_protected'
    #groups_string = action + '_groups'
    groups_string = action + '_protected'

    # get relevant part of policy from database
    select_string = select_string + ",policies.#{public_string},policies.#{friends_string},policies.#{groups_string}"
    get_policy select_string, contributable_id, contributable_type
      
    # if 'view/edit/download_public' then everyone is authorized
    if @policy_details[0]["#{public_string}"]
      is_authorized = true
    end

    # if 'view/edit/download_friends' and user is looged in, then determine whether current user is a friend
    if !is_authorized && @policy_details[0]["#{friends_string}"] && user_id != 0
      is_authorized = is_friend? @policy_details[0]['contributor_id'], user_id # are all contributions owned by users?
    end

    # if 'view/edit/download_groups' and user is logged in, determine whether owner and current_user share a group
    # possible won't be used if group access done through permissions
    if !is_authorized && @policy_details[0]["#{groups_string}"] && user_id != 0
      is_authorized = is_member_of_same_group? @policy_details[0]['contributor_id'], user_id # are all contributions owned by users?
    end

    # if none of the above but user is logged in, check permissions for the policy to determine if current_user has special permisssions
    # of if a group current_user belongs to has special permissions
    if !is_authorized && user_id != 0
      is_authorized = check_permissions @policy_details[0]['id'], action, user_id
    end

    # return is_authorized
    is_authorized
  end

  def check_permissions(policy_id, action, user_id)
    get_permissions policy_id

    # check permissions records for matching policy_id and current_user.id and decide if authorized
    @permissions_details.each do |permission|
      if permission['contributor_id'] == user_id && permission['contributor_type'] == 'User' && permission["#{action}"]
        return true
      end
    end

    # or check for matching policy_id and a group.id then check if current_user is member of group.id
    @permissions_details.each do |permission|
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

  def is_member_of_same_group?(contributor_id, user_id)
    # determine if owner and current_user share a group
    # unless not all groups get access and it is done through permissions instead

    # check all groups that contributor_id is a member of
    contributor_memberships = Membership.find_by_sql "SELECT network_id FROM memberships WHERE user_id=#{contributor_id}"

    contributor_memberships.each do |network|
      if is_member_of_group? user_id, network['network_id']
        return true
      end
    end

    # check all groups that contributor_id owns
    contributor_networks = Network.find_by_sql "SELECT id FROM networks WHERE user_id=#{contributor_id}"

    contributor_networks.each do |network|
      if is_member_of_group? user_id, network['id']
        return true
      end
    end

    false
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
    @policy_details = Policy.find_by_sql "SELECT #{select_string} FROM contributions,policies WHERE contributions.policy_id=policies.id AND contributions.contributable_id=#{contributable_id} AND contributions.contributable_type=\'#{contributable_type}\'"
  end

  # get all permissions related to policy
  def get_permissions(policy_id)
    select_string = 'contributor_id,contributor_type,download,edit,view'
    @permissions_details = Permission.find_by_sql "SELECT #{select_string} FROM permissions WHERE policy_id=#{policy_id}"
  end

end
