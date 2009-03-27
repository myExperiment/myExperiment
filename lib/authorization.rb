# myExperiment: lib/is_authorized.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Authorization

  # Authorization logic collected from enactment code

  # Note: at the moment (Feb 2008), Experiments (and associated Jobs) are
  # private to the owner, if a User owns it, OR accessible by all members of a
  # Group, if a Group owns it. 

  def Authorization.experiment_authorized?(experiment, action_name, user)
    return false if user.nil?
    
    case experiment.contributor_type.to_s
    when "User"
      return experiment.contributor_id.to_i == user.id.to_i
    when "Network"
      return experiment.contributor.member?(user.id)
    else
      return false
    end 
  end

  def Authorization.job_authorized?(job, action_name, user)
    # Use authorization logic from parent Experiment
    return Authorization.experiment_authorized?(job.experiment, action_name, user)
  end

  def Authorization.runner_authorized?(runner, action_name, user)
    return false if user.nil?
    
    case runner.contributor_type.to_s
    when "User"
      return runner.contributor_id.to_i == user.id.to_i
    when "Network"
      if ['edit','update','delete'].include?(action_name.downcase)
        return runner.contributor.owner?(user.id)
      else
        return runner.contributor.member?(user.id)
      end
    else
      return false
    end
  end

  # 1) action_name - name of the action that is about to happen with the "thing"
  # 2) thing_type - class name of the thing that needs to be authorized;
  #                 use NIL as a value of this parameter if an instance of the object to be authorized is supplied as "thing";
  # 3) thing - this is supposed to be an instance of the thing to be authorized, but
  #            can also accept an ID (since we have the type, too - "thing_type")
  # 4) user - can be either user instance or the ID (NIL or 0 to indicate anonymous/not logged in user)
  #
  # Note: there is no method overloading in Ruby and it's a good idea to have a default "nil" value for "user";
  #       this leaves no other choice as to have (sometimes) redundant "thing_type" parameter.
  def Authorization.is_authorized?(action_name, thing_type, thing, user=nil)
    thing_instance = nil
    thing_contribution = nil
    thing_id = nil
    user_instance = nil
    user_id = nil # if this value will not get updated by input parameters - user will be treated as anonymous

    # ***************************************
    #      Pre-checks on the Parameters
    # ***************************************

    # check first if the action that is being executed is known - not authorized otherwise
    action = categorize_action(action_name)
    return false unless action
    
    # if "thing" is unknown, or "thing" expresses ID of the object to be authorized, but "thing_type" is unknown - don't authorise the action
    # (this would allow, however, supplying no type, but giving the object instance as "thing" instead)
    return false if thing.blank? || (thing_type.blank? && thing.kind_of?(Fixnum))
    
    
    
    # some value for "thing" supplied - assume that the object exists; check if it is an instance or the ID
    if thing.kind_of?(Fixnum)
      # just an ID was provided - "thing_type" is assumed to have a type then
      thing_id = thing
    elsif thing.kind_of?(Contribution)
      # thing_type/_id should be properties of the actual "thing", not it's contribution
      thing_contribution = thing
      thing_type = thing_contribution.contributable_type
      thing_id = thing_contribution.contributable_id
    else
      # "thing" isn't an ID of the object; it's not a Contribution, 
      # so it must be an instance of the object to be authorized -- this can be:
      # -- "contributable" (workflow / file / pack) : (will still have to "find" the Contribution instance for this contributable aftewards)
      # OR
      # -- Network instance
      # -- Experiment / Job / Runner / TavernaEnactor instance
      # -- Comment
      # -- or any other object instance, for which we'll use the object itself to run .authorized?() on it
      thing_instance = thing
      thing_type = thing.class.name
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

    # if (thing_type, ID) pair was supplied instead of a "thing" instance,
    # need to find the object that needs to be authorized first;
    # (only do this for object types that are known to require authorization)
    #
    # this is required to get "policy_id" for policy-based aurhorized objects (like workflows / blobs / packs / contributions)
    # and to get objects themself for other object types (networks, experiments, jobs, tavernaenactors, runners)
    if (thing_contribution.nil? && ["Workflow", "Blob", "Pack", "Contribution"].include?(thing_type)) || 
       (thing_instance.nil? && ["Network", "Comment", "Experiment", "Job", "TavernaEnactor", "Runner"].include?(thing_type))
      
      found_thing = find_thing(thing_type, thing_id)
      
      unless found_thing
        # search didn't yield any results - the "thing" wasn't found; can't authorize unknown objects
        logger.error("UNEXPECTED ERROR - Couldn't find object to be authorized:(#{thing_type}, #{thing_id}); action: #{action_name}; user: #{user_id}")
        return false
      else
        if ["Workflow", "Blob", "Pack", "Contribution"].include?(thing_type)
          # "contribution" are only found for these three types of object (and the contributions themself),
          # for all the rest - use instances
          thing_contribution = found_thing
        else
          thing_instance = found_thing
        end
      end
    end
    

    # initially not authorized, so if all tests fail -
    # safe result of being not authorized will get returned 
    is_authorized = false
    
    case thing_type
      when "Workflow", "Blob", "Pack", "Contribution"
        unless user_id.nil?
          # access is authorized and no further checks required in two cases:
          # ** user is the owner of the "thing"
          return true if is_owner?(user_id, thing_contribution)
          
          # ** user is admin of the policy associated with the "thing"
          #    (this means that the user might not have uploaded the "thing", but
          #     is the one managing the access permissions for it)
          #
          #    it's fine if policy will not be found at this step - default one will get
          #    used further when required
          policy_id = thing_contribution.policy_id
          policy = get_policy(policy_id, thing_contribution)
          return false unless policy # if policy wasn't found (and default one couldn't be applied) - error; not authorized
          return true if is_policy_admin?(policy, user_id)
          
          
          # only owners / policy admins are allowed to perform actions categorized as "destroy";
          # hence "destroy" actions are not authorized below this point
          return false if action == "destroy"
          
          
          # user is not the owner/admin of the object; action is not of "destroy" class;
          # next thing - obtain all the permissions that are relevant to the user
          # (start with individual user permissions; group permissions will only
          #  be considered if that is required further on)
          user_permissions = get_user_permissions(user_id, policy_id)
          
          # individual user permissions override any other settings;
          # if several of these are found (which shouldn't be the case),
          # all are considered, but the one with "highest" access right is
          # used to make final decision -- that is if at least one of the
          # user permissions allows to make the action, it will be allowed;
          # likewise, if none of the permissions allow the action it will
          # not be allowed
          unless user_permissions.empty?
            authorized_by_user_permissions = false
            user_permissions.each do |p|
              authorized_by_user_permissions = true if permission_allows_action?(action, p)
            end
            return authorized_by_user_permissions
          end
          
          
          # no user permissions found, need to check what is allowed by policy
          # (if no policy was found, default policy is in use instead)
          authorized_by_policy = false
          authorized_by_policy = authorized_by_policy?(policy, thing_contribution, action, user_id)
          return true if authorized_by_policy
          

          # not authorized by policy, check the group permissions -- the ones
          # attached to "thing's" policy and belonging to the groups, where
          # "user" is a member or admin of;
          #
          # these cannot limit what is allowed by policy settings, only give more access rights 
          authorized_by_group_permissions = false
          group_permissions = get_group_permissions(policy_id)
          
          unless group_permissions.empty?
            group_permissions.each do |p|
              # check if this permission is applicable to the "user"
              if permission_allows_action?(action, p) && (is_network_member?(user_id, p.contributor_id) || is_network_admin?(user_id, p.contributor_id))
                authorized_by_group_permissions = true
                break
              end
            end
            return authorized_by_group_permissions if authorized_by_group_permissions
          end
          
          # user permissions, policy settings and group permissions didn't give the
          # positive result - decline the action request
          return false
        
        else
          # this is for cases where trying to authorize anonymous users;
          # the only possible check - on public policy settings:
          policy_id = thing_contribution.policy_id
          policy = get_policy(policy_id, thing_contribution)
          return false unless policy # if policy wasn't found (and default one couldn't be applied) - error; not authorized
          
          return authorized_by_policy?(policy, thing_contribution, action, nil)
        end
        
      when "Network"
        case action
          when "edit", "destroy"
            # check to allow only admin to edit / delete the group
            is_authorized = is_network_admin?(user_id, thing_id)
          else
            is_authorized = true
        end
      
      when "Comment"
        case action
          when "destroy"
            # only the user who posted the comment can delete it
            is_authorized = Authorization.is_owner?(user_id, thing_instance)
          when "view"
            # user can view comment if they can view the item that this comment references 
            is_authorized = Authorization.is_authorized?('view', thing_instance.commentable_type, thing_instance.commentable_id, user)
          else
            # 'edit' or any other actions are not allowed on comments
            is_authorized = false
        end
      
      when "Experiment"

        user_instance = get_user(user_id) unless user_instance

        # "action_name" used to work with original action name, rather than classification made inside the module
        is_authorized = Authorization.experiment_authorized?(thing_instance, action_name, user)

      when "TavernaEnactor", "Runner"

        user_instance = get_user(user_id) unless user_instance

        # "action_name" used to work with original action name, rather than classification made inside the module
        is_authorized = Authorization.runner_authorized?(thing_instance, action_name, user)

      when "Job"

        user_instance = get_user(user_id) unless user_instance
        
        # "action_name" used to work with original action name, rather than classification made inside the module
        is_authorized = Authorization.job_authorized?(thing_instance, action_name, user)
      
      else
        # don't recognise the kind of "thing" that is being authorized, so
        # we don't specifically know that it needs to be blocked;
        # therefore, allow any actions on it
        is_authorized = true
    end
    
    return is_authorized
    
  end


  private

  def Authorization.categorize_action(action_name)
    case action_name
      when 'show', 'index', 'view', 'search', 'favourite', 'favourite_delete', 'comment', 'comment_delete', 'comments', 'comments_timeline', 'rate', 'tag',  'items', 'statistics', 'tag_suggestions', 'read', 'verify'
        action = 'view'
      when 'edit', 'new', 'create', 'update', 'new_version', 'create_version', 'destroy_version', 'edit_version', 'update_version', 'new_item', 'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link', 'process_tag_suggestions'
        action = 'edit'
      when 'download', 'named_download', 'launch', 'submit_job', 'save_inputs', 'refresh_status', 'rerun', 'refresh_outputs'
        action = 'download'
      when 'destroy', 'delete', 'destroy_item'
        action = 'destroy'
      when 'execute'
        # action is available only(?) for runners at the moment;
        # possibly, "launch" action for workflows should be moved into this category, too
        action = 'execute'
      else
        # unknown action
        action = nil
    end
    
    return action
  end

  # check if the DB holds entry for the "thing" to be authorized 
  def Authorization.find_thing(thing_type, thing_id)
    found_instance = nil
    
    begin
      case thing_type
        when "Workflow", "Blob", "Pack"
          # "find_by_sql" works faster itself PLUS only a subset of all fields is selected;
          # this is the most frequent query to be executed, hence needs to be optimised
          found_instance = Contribution.find_by_sql "SELECT contributor_id, contributor_type, policy_id FROM contributions WHERE contributable_id=#{thing_id} AND contributable_type='#{thing_type}'"
          found_instance = (found_instance.empty? ? nil : found_instance[0]) # if nothing was found - nil; otherwise - first match
        when "Contribution"
          # fairly possible that it's going to be a contribution itself, not a contributable
          found_instance = Contribution.find(thing_id)
        when "Network"
          found_instance = Network.find(thing_id)
        when "Comment"
          found_instance = Comment.find(thing_id)
        when "Experiment"
          found_instance = Experiment.find(thing_id)
        when "Job"
          found_instance = Job.find(thing_id)
        when "TavernaEnactor"
          found_instance = TavernaEnactor.find(thing_id)
        when "Runner"
          # the line below doesn't have a typo - "runners" should really be searched in "TavernaEnactor" model
          found_instance = TavernaEnactor.find(thing_id)
      end
    rescue ActiveRecord::RecordNotFound
      # do nothing; makes sure that app won't crash when the required object is not found;
      # the method will return "nil" anyway, so no need to take any further actions here
    end
    
    return found_instance
  end


  # checks if "user" is owner of the "thing"
  def Authorization.is_owner?(user_id, thing)
    is_authorized = false

    case thing.class.name
      when "Contribution"
        # if owner of the "thing" is the "user" then the "user" is authorized
        if thing.contributor_type == 'User' && thing.contributor_id == user_id
          is_authorized = true
        elsif thing.contributor_type == 'Network'
          is_authorized = is_network_admin?(user_id, thing.contributor_id)
        end
      when "Comment"
        is_authorized = (thing.user_id == user_id)
      #else
        # do nothing -- unknown "thing" types are not authorized by default 
    end

    return is_authorized
  end
  
  # checks if "user" is admin of the policy associated with the "thing"
  def Authorization.is_policy_admin?(policy, user_id)
    # if anonymous user or no policy provided - definitely not policy admin
    return false unless (policy && user_id)
    
    return(policy.contributor_type == 'User' && policy.contributor_id == user_id)
  end
  
  
  def Authorization.is_network_admin?(user_id, network_id)
    # checks if there is a network with ID(network_id) which has admin with ID(user_id) -
    # if found, user with ID(user_id) is an admin of that network 
    network = Network.find_by_sql "SELECT user_id FROM networks WHERE id=#{network_id} AND user_id=#{user_id}"
    return(!network.blank?)
  end
  
  
  def Authorization.is_network_member?(user_id, network_id)
    # checks if user with ID(user_id) is a member of the group ID(network_id)
    membership = Membership.find_by_sql "SELECT id FROM memberships WHERE user_id=#{user_id} AND network_id=#{network_id} AND user_established_at IS NOT NULL AND network_established_at IS NOT NULL"
    return(!membership.blank?)
  end
  
  
  # checks if two users are friends
  def Authorization.is_friend?(contributor_id, user_id)
    friendship = Friendship.find_by_sql "SELECT id FROM friendships WHERE (user_id=#{contributor_id} AND friend_id=#{user_id}) OR (user_id=#{user_id} AND friend_id=#{contributor_id}) AND accepted_at IS NOT NULL"
    return(!friendship.blank?)
  end
  
  
  # gets the user object from the user_id;
  # used by is_authorized when calling model.authorized? method for classes that don't use policy-based authorization
  def Authorization.get_user(user_id)
    return nil if user_id == 0
    
    begin
      user = User.find(:first, :conditions => ["id = ?", user_id])
      return user
    rescue ActiveRecord::RecordNotFound
      # user not found, "nil" for anonymous user will be returned
      return nil
    end
  end
  
  
  # query database for relevant fields in policies table
  #
  # Parameters:
  # 1) policy_id - ID of the policy to find in the DB;
  # 2) thing_contribution - Contribution object for the "thing" that is being authorized;
  def Authorization.get_policy(policy_id, thing_contribution)
    unless policy_id.blank?
      select_string = 'id, contributor_id, contributor_type, share_mode, update_mode'
      policy_array = Policy.find_by_sql "SELECT #{select_string} FROM policies WHERE policies.id=#{policy_id}"
      
      # if nothing's found, use the default policy
      policy = (policy_array.blank? ? get_default_policy(thing_contribution) : policy_array[0])
    else
      # if the "policy_id" turns out unknown, use default policy
      policy = get_default_policy(thing_contribution)
    end
    
    return policy
  end
  
  
  # if a policy instance not found to be associated with the Contribution of a "thing", use a default one
  def Authorization.get_default_policy(thing_contribution)
    # an unlikely event that contribution doesn't have a policy - need to use
    # default one; "owner" of the contribution will be treated as policy admin
    #
    # the following is slow, but given the very rare execution can be kept
    begin
      # thing_contribution is Contribution, so thing_contribution.contributor is the original uploader == owner of the item
      contributor = eval("#{thing_contribution.contributor_type}.find(#{thing_contribution.contributor_id})")
      policy = Policy._default(contributor)
      return policy
    rescue ActiveRecord::RecordNotFound => e
      # original contributor not found, but the Contribution entry still exists -
      # this is an error in associations then, because all dependent items
      # should have been deleted along with the contributor entry; log the error
      logger.error("UNEXPECTED ERROR - Contributor object missing for an existing contribution: (#{thing_contribution.class.name}, #{thing_contribution.id})")
      logger.error("EXCEPTION:" + e)
      return nil
    end
  end
  
  
  # get all user permissions related to policy for the "thing" for "user"
  def Authorization.get_user_permissions(user_id, policy_id)
    unless user_id.blank? || policy_id.blank?
      select_string = 'contributor_id, download, edit, view'
      Permission.find_by_sql "SELECT #{select_string} FROM permissions WHERE policy_id=#{policy_id} AND contributor_type='User' AND contributor_id=#{user_id}"
    else
      # an empty array to be returned has the same effect as if no permissions were found anyway
      return []
    end
  end
  
  
  # get all group permissions related to policy for the "thing"
  def Authorization.get_group_permissions(policy_id)
    unless policy_id.blank?
      select_string = 'contributor_id, download, edit, view'
      Permission.find_by_sql "SELECT #{select_string} FROM permissions WHERE policy_id=#{policy_id} AND contributor_type='Network'"
    else
      # an empty array to be returned has the same effect as if no permissions were found anyway
      return []
    end
  end
  

  # checks whether "user" is authorized for "action" on "thing"
  def Authorization.authorized_by_policy?(policy, thing_contribution, action, user_id)
    is_authorized = false
    
    # NB! currently myExperiment won't support objects owned by entities other than users
    # (especially, policy checks are not agreed for these cases - however, owner tests and
    #  permission tests are possible and will be carried out)
    unless thing_contribution.contributor_type == "User"
      return false
    end
    
    ####################################################################################
    #
    # For details on what each sharing / updating mode means, see the wiki:
    # http://wiki.myexperiment.org/index.php/Developer:Ownership_Sharing_and_Permissions
    #
    ####################################################################################
    share_mode = policy.share_mode
    update_mode = policy.update_mode

    case action
      when 'view'
        if (share_mode == 0 || share_mode == 1 || share_mode == 2)
          # if share mode is 0,1,2, anyone can view
          is_authorized = true
        elsif !user_id.nil? && (share_mode == 3 || share_mode == 4 || update_mode == 1)
          # if share mode is 3,4, friends can view; AND friends can also view if update mode is 1 -- due to cascading permissions
          is_authorized = is_friend?(thing_contribution.contributor_id, user_id)
        end
        
      when 'download'
        if (share_mode == 0)
          # if share mode is 0, anyone can download
          is_authorized = true
        elsif !user_id.nil? && (share_mode == 1 || share_mode == 3 || update_mode == 1)
          # if share mode is 1,3, friends can download; AND if update mode is 1, friends can download too -- due to cascading permissions
          is_authorized = is_friend?(thing_contribution.contributor_id, user_id)
        end
      when 'edit'
        if (update_mode == 0 && share_mode == 0)
          # if update mode is 0, anyone with view & download permissions can edit (sharing mode 0 for anonymous)
          is_authorized = true
        elsif !user_id.nil? && (update_mode == 1 || (update_mode == 0 && (share_mode == 1 || share_mode == 3)))
          # if update mode is 1, friends can edit; AND if update mode is 0 and friends have view & download permissions, they can edit
          is_authorized = is_friend?(thing_contribution.contributor_id, user_id)
        end
    end

    return is_authorized
  end
  
  
  # checks if a permission instance allows certain action taking into account cascading permissions
  #
  # NB! caller of this method *assumes* that the permission belongs to the user, for which
  #     authorization is performed  
  def Authorization.permission_allows_action?(action, permission)
    # check that a permission instance was supplied
    return false unless permission
    
    case action
      when "view"
        return (permission.attributes["view"] || permission.attributes["download"] || permission.attributes["edit"])
      when "download"
        return (permission.attributes["download"] || permission.attributes["edit"])
      when "edit"
        return permission.attributes["edit"]
      else
        # any other type of action is not allowed by permissions
        return false
    end
  end

end
