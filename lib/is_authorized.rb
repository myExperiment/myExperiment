# myExperiment: lib/is_authorized.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module IsAuthorized

  # check the relevant permissions based on 'action' string
  
  # 1) action_name - name of the action that is about to happen with the "thing"
  # 2) thing_type - class name of the thing that needs to be authorized
  # 3) thing - this is supposed to be an instance of the thing to be authorized, but
  #            can also accept an ID (since we have the type, too - "thing_type")
  # 4) user - can be either user instance or the ID (NIL or 0 to indicate anonymous/not logged in user)
  #
  # Note: there is no method overloading in Ruby and it's a good idea to have a default "nil" value for "user";
  #       this leaves no other choice as to have (sometimes) redundant "thing_type" parameter.
  def is_authorized?(action_name, thing_type, thing, user=nil)
    thing_instance = nil
    user_instance = nil


    # check first if the action that is being executed is known - not authorized otherwise
    action = categorize_action(action_name)
    return false unless action
    
    # if thing_type or thing itself are unknown - don't authorise the action
    return false if (thing_type.blank? || thing.blank?)
    
    # some value for "thing" supplied - assume that the object exists; check if it is an instance or the ID
    if thing.kind_of?(Fixnum)
      thing_id = thing
    else
      thing_instance = thing
      thing_id = thing.id
    end
    
    if user.kind_of?(User)
      user_instance = user
      user_id = user.id
    elsif user == 0
      # "Authenticated System" sets current_user to 0 if not logged in (i.e. anonymous user)
      user_id = nil
    elsif user.nil? || user.kind_of?(Fixnum)
      # anonymous user OR only id of the user, not an instance was provided;
      user_id = user
    end
    

    # ***************************************
    #      Actual Authorization Begins 
    # ***************************************

    # initially not authorized, so if all tests fail -
    # safe result of being not authorized will get returned 
    is_authorized = false
    policy_id = nil
    
    case thing_type
      when "Workflow", "Blob", "Pack"
        # TODO: solve this
        
        # !!# Bit of hack for update permissions - 'view' and 'download' is authorized if 'edit' is authorized
        # !! return true if ['download', 'view'].include?(category) and authorized?('edit', c_ution, c_utor)

        authorized_by_policy = false 
        authorized_by_user_permissions = false
        authorized_by_group_permissions = false
        
        unless user_id.nil?
          # access is authorized and no further checks required in two cases:
          # * user is the owner of the "thing"
          # * user is admin of the policy associated with the "thing"
          #   (this means that the user might not have uploaded the "thing", but
          #    is the one managing the access permissions for it)
  # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
          contribution_found, user_is_owner, policy_id = is_owner?(user_id, thing_type, thing_id)
          return true if (user_is_owner || admin?(c_utor))
          
          
          # c_utor is not the owner of the item, to which policy is attached;
          # next thing - obtain all the permissions that are relevant to
          # c_utor: either through individual or through group permissions
          user_permissions, group_permissions = all_permissions_for_contributor(c_utor)
          
          # DEBUG
          #logger.error "==================================================="
          #logger.error "user_permissions -> " + user_permissions.length.to_s
          #logger.error user_permissions.to_sentence
          #logger.error "group_permissions -> " + group_permissions.length.to_s
          #logger.error group_permissions.to_sentence
          #logger.error "==================================================="
          # END OF DEBUG
          
          
          # individual ('user') permissions override any other settings
          # (if several are found, which shouldn't be the case, all are collapsed into
          #  one with the highest access rights)
          unless user_permissions.empty?
            user_permissions.each do |p|
              authorized_by_user_permissions = true if p.attributes["#{category}"]
            end
            return authorized_by_user_permissions
          end
          
          
          # no user permissions found, need to check what is allowed by policy
          # (check 'protected' settings first)
          if c_ution
            # true if contribution.contributor and contributor are related and policy[category_protected]
            authorized_by_policy = true if (c_ution.contributor.protected? c_utor and protected?(category))
          else
            # true if policy.contributor and contributor are related and policy[category_protected]
            authorized_by_policy = true if (self.contributor.protected? c_utor and protected?(category))
          end
          return authorized_by_policy if authorized_by_policy
          
          
          # not authorized by protected settings; check public policy settings
          authorized_by_policy = public?(category)
          return authorized_by_policy if authorized_by_policy
          
          
          # not authorized by policy at all, check the group permissions
          # (for the groups, where c_utor is a member or admin of)
          unless group_permissions.empty?
            group_permissions.each do |p|
              authorized_by_group_permissions = true if p.attributes["#{category}"]
            end
            return authorized_by_group_permissions if authorized_by_group_permissions
          end
        end
        
        # no other cases matched OR c_utor is unknown - apply public policy settings
        # true if policy[category_public]
        return public?(category)
   # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        
      when "Network"
        
      when "Experiment", "Job", "TavernaEnactor", "Runner"
      
      else
        # don't recognise the kind of thing that is being authorized, so
        # we don't specifically know that it needs to be blocked;
        # therefore, allow any actions on it
        is_authorized = true
    end
    
    return is_authorized
    
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



    # authorization rules for non-contributable classes
    if thing_type == 'Network'
      is_authorized = true
    elsif thing_type == 'Experiment'
      # call Experiment.authorized?
      experiment = Experiment.find(:first, :conditions => ["id = ?", thing_id])
      user = get_user(user_id)
      is_authorized = experiment.authorized?(action_name, user)
    elsif thing_type == 'Job'
      # use Job.authorized?
      job = Job.find(:first, :conditions => ["id = ?", thing_id])
      user = get_user(user_id)
      is_authorized = job.authorized?(action_name, user)
    elsif thing_type == 'TavernaEnactor' || thing_type == 'Runner'
      # use TavernaEnactor.authorized?
      enactor = TavernaEnactor.find(:first, :conditions => ["id = ?", thing_id])
      user = get_user(user_id)
      is_authorized = enactor.authorized?(action_name, user)
    # only workflow, blobs and packs use policy-based auth
    elsif thing_type == 'Workflow' || thing_type == 'Blob' || thing_type == 'Pack'
      # check if current user owns contributable
      if user_id != 0
        is_authorized = is_owner?(thing_id, thing_type, user_id)
      end

      # if current user isn't the owner and the action isn't destroy then check the policy
      # (only the owner can destroy something)
      if !is_authorized && action != 'destroy'
        is_authorized = check_policy(action, thing_id, thing_type, user_id)
      end
    # if thing does not match anything above, default to true
    else
      is_authorized = true
    end

    is_authorized
  end

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  private

  def categorize_action(action_name)
    case action_name
      when 'show', 'index', 'view', 'search', 'favourite', 'favourite_delete', 'comment', 'comment_delete', 'comments', 'comments_timeline', 'rate', 'tag',  'items', 'statistics', 'tag_suggestions'
        action = 'view'
      when 'new', 'create', 'update', 'edit', 'new_version', 'create_version', 'destroy_version', 'edit_version', 'update_version', 'new_item', 'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link'
        action = 'edit'
      when 'download', 'named_download', 'launch', 'submit_job'
        action = 'download'
      when 'destroy', 'destroy_item'
        action = 'destroy'
      else
        # unknown action
        action = nil
    end
    
    return action
  end


  # check if "user" is owner of the "thing"
  def is_owner?(user_id, thing_type, thing_id)
    is_authorized = false

    # get owner of the "thing" from database
    contribution = Contribution.find_by_sql "SELECT contributor_id, contributor_type, policy_id FROM contributions WHERE contributable_id='#{thing_id}' AND contributable_type='#{thing_type}'"

    # if nothing found, return 

    # if owner of the "thing" is the "user" then the "user" is authorized
    if contribution[0]['contributor_type'] == 'User' && contribution[0]['contributor_id'] == user_id
      is_authorized = true
    elsif contribution[0]['contributor_type'] == 'Network'
      is_authorized = is_network_admin?(user_id, contribution[0]['contributor_id'])
    end

    return [is_authorized, contribution[0]['policy_id']]
  end

#  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  # check whether current user is authorized for 'action' on 'contributable_*'
  def check_policy(action, contributable_id, contributable_type, user_id)
    is_authorized = false
    # get relevant part of policy from database
    select_string = 'policies.id,policies.contributor_id,policies.contributor_type,policies.share_mode,policies.update_mode'
    policy_details = get_policy(select_string, contributable_id, contributable_type)
    
    # if there is no policy, or policy is owned by a network assume private
    # (contributions owned by networks is currently not supported)
    if policy_details.length == 0 || policy_details[0]['contributor_type'] == 'Network'
      return false
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
        is_authorized = true
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
        if is_network_member?(user_id, permission['contributor_id'])
          return true
        end
      end
    end

    false
  end

  def is_friend?(contributor_id, user_id)
    friendship = Friendship.find_by_sql "SELECT id FROM friendships WHERE (user_id=#{contributor_id} AND friend_id=#{user_id}) OR (user_id=#{user_id} AND friend_id=#{contributor_id}) AND accepted_at IS NOT NULL"

    if friendship.length > 0
      return true
    else
      return false
    end
  end

  def is_network_member?(user_id, network_id)
    membership = Membership.find_by_sql "SELECT id FROM memberships WHERE user_id=#{user_id} AND network_id=#{network_id} AND user_established_at IS NOT NULL AND network_established_at IS NOT NULL"

    # check if there is a membership record for user_id and network_id
    if membership.length > 0
      return true
    else
      # if there is no membership record check whether user_id is the owner of network_id
      return is_network_admin?(user_id, network_id)
    end
  end
  
  def is_network_admin?(user_id, network_id)
    network = Network.find_by_sql "SELECT user_id FROM networks WHERE user_id=#{user_id} AND id=#{network_id}"
    
    if network.length > 0
      is_admin = true
    else
      is_admin = false
    end
    
    is_admin
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
