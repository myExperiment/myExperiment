# myExperiment: lib/authorization.rb
# 
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

module Authorization

  # Authorisation check for instances and classes of objects.
  #
  # Arguments:
  #
  # action      - This string describes the action to be performed, e.g.
  #               'create', 'read', 'update' or 'destroy'.
  #
  # object      - This is the object being acted upon, e.g. an instance of a
  #               Comment or an instance of a Workflow.
  #
  # user        - The user that the check is with respect to.  Typically,
  #               this would be current_user.
  #
  # context     - This is the context in which the object or object to be
  #               created is made.  For example, pack entries can only be
  #               created by those that can edit the pack that the entry will
  #               be made in, so the context here would be an instance of the
  #               pack in question.  This is only usually required for 'create'
  #               actions.

  def self.check(action, object, user, context = nil)

    valid_actions = ["create", "view", "edit", "destroy", "download", "execute"]

    # This behaviour isn't ideal, but the old authorisation function would just
    # return false with invalid arguments.  I'll have this in here until I can
    # remove it.

    return false if action.nil? || object.nil?
    # raise "Missing action in authorisation check" unless action
    # raise "Missing object in authorisation check" unless object

    # If it is a contribution, then work on the contributable instead.  I'm not
    # sure this is still needed and I'll remove it if I can.

    object = object.contributable if object.kind_of?(Contribution)

    raise "Invalid action ('#{action}') in authorisation check" unless action && valid_actions.include?(action)

    # Set the user to nil if there is no user (e.g. 0 becomes nil).

    user = nil unless user.kind_of?(User)
    
    object_type = object.class == Class ? object.name : object.class.name

    case object_type

      when "Workflow", "Blob", "Pack", "Service", "Contribution"

        # workflows can only be created by authenticated users
        if (action == "create") && [Workflow, Blob, Pack].include?(object)
          return !user.nil?
        end

        # the owner of a contributable can perform all actions on it
        return true if object.contributor == user

        # get the object with edit, view and download permissions attached
        ob = Authorization.scoped(object.class, :permissions_only => true, :authorised_user => user).find_by_id(object.id)

        # not getting an object means that there is no view permission
        return false if ob.nil?

        # return the response
        case action
          when "view";     return ob.view_permission.to_s == "1"
          when "download"; return ob.download_permission.to_s == "1"
          when "edit";     return ob.edit_permission.to_s == "1"
          else;            return false
        end
        
      when "Network"
        case action
          when "edit", "destroy"
            # check to allow only admin to edit / delete the group
            return user && user.network_admin?(object.id)
          else
            return true
        end
      
      when "PackVersion"
        case action
          when "create"

            # If a user can edit a pack, they can create a version of it.
            is_authorized = Authorization.check('edit', context, user)

          when "view"

            # If a user can view a pack, they can view versions of it.
            is_authorized = Authorization.check('view', context, user)

          else
            
            # Editing or deleting versions of a pack is not allowed.
            is_authorized = false
        end

      when "Comment"
        case action
          when "create"

            # Comments can be created by authenticated users that can view the context
            return !user.nil? && Authorization.check('view', context, user)

          when "destroy"

            # Users can delete their own comments.  Curators and
            # administrators can delete any comment.
  
            return object.user == user || (user && user.admin?) || (user && user.curator?)

          when "view"
            # user can view comment if they can view the item that this comment references 
            return Authorization.check('view', object.commentable, user)
          else
            # 'edit' or any other actions are not allowed on comments
            return false
        end
      
      when "Rating"
        case action
          when "create"

            # Ratings can be created by authenticated users that can view the context
            return !user.nil? && Authorization.check('view', context, user)

          when "edit", "destroy"

            # Users can edit or remove their own ratings
            return !user.nil? && object.user == user
        end

      when "Tagging"
        case action
          when "create"

            # Taggings can be created by authenticated users that can view the context
            return !user.nil? && Authorization.check('view', context, user)

          when "destroy"

            # Users can delete their own taggings
            return !user.nil? && object.user == user
        end

      when "Bookmark"
        case action
          when "create"
            # Bookmarks can be created by authenticated users that can view the context
            return !user.nil? && Authorization.check('view', context, user)
          when "destroy"
            # only the user who created the bookmark can delete it
            return object.user == user
          when "view"
            # everyone can view bookmarks
            return true

          else
            # 'edit' or any other actions are not allowed on comments
            return false
        end
      
      when "Experiment"

        return false if user.nil?

        case object.contributor_type.to_s
        when "User"
          return object.contributor_id.to_i == user.id.to_i
        when "Network"
          return object.contributor.member?(user.id)
        else
          return false
        end 

      when "TavernaEnactor", "Runner"

        return false if user.nil?

        case object.contributor_type.to_s
        when "User"
          return object.contributor_id.to_i == user.id.to_i
        when "Network"
          if ['edit', 'destroy'].include?(action.downcase)
            return object.contributor.owner?(user.id)
          else
            return object.contributor.member?(user.id)
          end
        else
          return false
        end

      when "Job"

        return false if user.nil?

        case object.experiment.contributor_type.to_s
        when "User"
          return object.experiment.contributor_id.to_i == user.id.to_i
        when "Network"
          return object.experiment.contributor.member?(user.id)
        else
          return false
        end 
      
      when "ContentType"

        case action

          when "view"
            # anyone can view content types
            return true
     
          when "edit"
            # the owner of the content type can edit
            return !user.nil? && object.user == user

          when "destroy"
            # noone can destroy them yet - they just fade away from view
            return false
        end

      when "User"

        case action

          when "view"
            # everyone can view users
            return true

          when "edit"
            # the owner of a user record can edit
            return !user.nil? && user == object

          when "destroy"
            # only adminstrators can delete accounts at present
            return user && user.admin?
        end

      when "Picture"

        case action

          when "view"
            # owner can view all their pictures
            return true if object.owner == user

            # anyone can view a user's selected pictures
            return object.selected?

          when "edit", "destroy"
            # only the owner of a picture can edit/destroy
            return object.owner == user
        end

      when "ClientApplication"

          return object.user == user

      when "Ontology"

        case action

          when "create"
            #  Authenticated users can create ontologies
            return !user.nil?

          when "view"
            # All users can view
            return true

          when "edit", "destroy"
            # Users can edit and destroy their own ontologies
            return object.user == user
        end

      when "Predicate"

        case action

          when "create"

            raise "Context required for authorisation check" unless context

            # Only users that can edit an ontology can add predicates to it
            return !user.nil? && Authorization.check('edit', context, user)

          when "view"
            # All users can view predicates
            return true

          else
            # All other predicate permissions are inherited from the ontology
            return Authorization.check('edit', object.ontology, user)
        end

      when "Relationship"

        case action

          when "create"

            raise "Context required for authorisation check" unless context

            # Only users that can edit a pack can add relationships to it
            return !user.nil? && Authorization.check('edit', context, user)

          when "view"
            # Users that can view the context can view the relationship
            return Authorization.check('view', object.context, user)

          else
            # All other relationship permissions depend on edit access to the context
            return Authorization.check('edit', object.context, user)
        end

      when "PackContributableEntry", "PackRemoteEntry"

        case action

          when "create"

            raise "Context required for authorisation check" unless context

            # Only users that can edit a pack can add items to it
            return !user.nil? && Authorization.check('edit', context, user)

          when "edit", "destroy"
            # Users that can edit the pack can also edit / delete items
            return Authorization.check('edit', object.pack, user)

        end

      when "Message"
        case action
          when "view"
            return object.to == user.id || object.from == user.id
          when "destroy"
            return object.to == user.id
        end
      else
        # don't recognise the kind of object that is being authorized, so
        # we don't specifically know that it needs to be blocked;
        # therefore, allow any actions on it

        return true
    end
    
    is_authorized
  end

  def self.scoped(model, opts = {})

    def self.view_conditions(user_id, friends, networks)

      return "((contributions.id IS NULL) OR (share_mode = 0 OR share_mode = 1 OR share_mode = 2))" if user_id.nil?

      policy_part =
        "((contributions.contributor_type = 'User' AND contributions.contributor_id = #{user_id}) OR
          (share_mode = 0 OR share_mode = 1 OR share_mode = 2) OR
          ((share_mode = 1 OR share_mode = 3 OR share_mode = 4 OR update_mode = 1 OR (update_mode = 0 AND (share_mode = 1 OR share_mode = 3))) AND
           (contributions.contributor_type = 'User' AND contributions.contributor_id IN #{friends})))"

      "((contributions.id IS NULL) OR (#{policy_part} OR #{permission_part(['view', 'download', 'edit'], user_id, networks)}))"
    end

    def self.download_conditions(user_id, friends, networks)

      return "((contributions.id IS NULL) OR (share_mode = 0))" if user_id.nil?

      policy_part = 
        "((contributions.contributor_type = 'User' AND contributions.contributor_id = #{user_id}) OR
          (share_mode = 0) OR
          ((share_mode = 1 OR share_mode = 3 OR update_mode = 1 OR (update_mode = 0 AND (share_mode = 1 OR share_mode = 3))) AND
           (contributions.contributor_type = 'User' AND contributions.contributor_id IN #{friends})))"

      "((contributions.id IS NULL) OR (#{policy_part} OR #{permission_part(['download', 'edit'], user_id, networks)}))"
    end

    def self.edit_conditions(user_id, friends, networks)

      return "((contributions.id IS NULL) OR (share_mode = 0 AND update_mode = 0))" if user_id.nil?

      policy_part =
        "((contributions.contributor_type = 'User' AND contributions.contributor_id = #{user_id}) OR
          (share_mode = 0 AND update_mode = 0) OR
          ((update_mode = 1 OR (update_mode = 0 AND (share_mode = 1 OR share_mode = 3))) AND
           (contributions.contributor_type = 'User' AND contributions.contributor_id IN #{friends})))"

      "((contributions.id IS NULL) OR (#{policy_part} OR #{permission_part(['edit'], user_id, networks)}))"
    end

    def self.permission_part(permissions, user_id, networks)

      permission_test = permissions.map do |p| "permissions.#{p} = true" end.join(" OR ")

      "(permissions.id IS NOT NULL AND (#{permission_test}) AND
        ((permissions.contributor_type = 'User'    AND permissions.contributor_id = #{user_id}) OR
         (permissions.contributor_type = 'Network' AND permissions.contributor_id IN #{networks})))"
    end

    user = opts.delete(:authorised_user)

    if (user != 0) && (user != nil)

      user_id = user.id

      friend_ids = user.friendships_accepted.map  do |fs| fs.user_id   end +
                   user.friendships_completed.map do |fs| fs.friend_id end

      network_ids = (user.networks_owned + user.networks).map do |n| n.id end

      friends  = friend_ids.empty?  ? "(-1)" : "(#{friend_ids.join(",")})"
      networks = network_ids.empty? ? "(-1)" : "(#{network_ids.join(",")})"
    end

    # By default, the objects to authorize are the actual objects that the
    # association returns.  However you can specify an alternate type/id if
    # this is different.
    #
    # For example, the association might return Taggings but Tagging objects do
    # not support authorization in themselves but by association with the
    # taggable association.
    #
    # In this case, :auth_type would be "taggings.taggable_type" and :auth_id
    # authorize would be "taggings.taggable_id".

    auth_id   = opts.delete(:auth_id)   || "#{model.table_name}.id"
    auth_type = opts.delete(:auth_type) || "'#{model.name}'"

    # Joins

    joins = []

    joins.push("LEFT OUTER JOIN contributions ON contributions.contributable_id = #{auth_id} AND contributions.contributable_type = #{auth_type}") if model != Contribution
    joins.push("LEFT OUTER JOIN policies ON contributions.policy_id = policies.id")
    joins.push("LEFT OUTER JOIN permissions ON policies.id = permissions.policy_id")

    # Include the effective permissions in the result?

    include_permissions = opts.delete(:include_permissions)
    permissions_only    = opts.delete(:permissions_only)

    select_parts = []

    select_parts << "#{model.table_name}.*" if include_permissions

    if include_permissions || permissions_only

      view_conditions     = view_conditions(user_id, friends, networks)
      download_conditions = download_conditions(user_id, friends, networks)
      edit_conditions     = edit_conditions(user_id, friends, networks)

      select_parts << "BIT_OR(#{view_conditions})     AS view_permission"
      select_parts << "BIT_OR(#{download_conditions}) AS download_permission"
      select_parts << "BIT_OR(#{edit_conditions})     AS edit_permission"
    end

    opts[:select] = select_parts.join(", ") unless select_parts.empty?
    opts[:conditions] = view_conditions(user_id, friends, networks)
    opts[:group] ||= 'contributions.contributable_type, contributions.contributable_id'
    opts[:joins] = joins

    scope = model.scoped(opts) do
      def permission_conditions
        @permission_conditions
      end

      def permission_conditions=(permission_conditions)
        @permission_conditions = permission_conditions
      end
    end

    scope.permission_conditions = {
      :view_conditions     => view_conditions,
      :download_conditions => download_conditions,
      :edit_conditions     => edit_conditions
    }

    scope
  end
end

