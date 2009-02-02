# myExperiment: app/models/policy.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Policy < ActiveRecord::Base
  #validates_uniqueness_of :name, :scope => [:contributor_id, :contributor_type]
  
  belongs_to :contributor, :polymorphic => true
  
  has_many :contributions,
           :dependent => :nullify,
           :order => "contributable_type ASC"
  
  has_many :permissions,
           :dependent => :destroy,
           :order => "created_at ASC"
  
  validates_presence_of :contributor, :name
  
  def authorized?(action_name, c_ution=nil, c_utor=nil)
    
    if c_ution
      # return false unless correct policy for contribution
      return false unless c_ution.policy.id.to_i == id.to_i
    end
    
    # ======= Authorization logic continues... ======
    
    # Authenticated system sets current_user to 0 if not logged in
    c_utor = nil if c_utor == 0
      
    # false unless action can be categorized
    return false unless category = categorize(action_name)
    
    # Bit of hack for update permissions - 'view' and 'download' is authorized if 'edit' is authorized
    return true if ['download', 'view'].include?(category) and authorized?('edit', c_ution, c_utor) 
      
    
    authorized_by_user_permissions = false
    authorized_by_policy = false 
    authorized_by_group_permissions = false
    
    unless c_utor.nil?
      # being owner of the contribution / admin of the policy is the most important -
      # if this is the case, no further checks are required: access is authorized
      if c_ution
        # true if owner of contribution or administrator of contribution.policy
        return true if (c_ution.owner?(c_utor) or c_ution.admin?(c_utor))
      else
        # true if administrator of self
        return true if admin?(c_utor)
      end
      
      
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
  end
  
  def admin?(c_utor)
    return false unless c_utor
    
    contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
  end
  
  # THIS IS THE DEFAULT POLICY (see /app/views/policies/_list_form.rhtml)
  # IT IS CALLED IN contribution.rb::authorized? ; application.rb::update_policy()
  def self._default(c_utor, c_ution=nil)
    rtn = Policy.new(:name => "A default policy",  # "anyone can view and download and no one else can edit"
                     :contributor => c_utor,
                     :share_mode => 0,
                     :update_mode => 6)     
                     
    c_ution.policy = rtn unless c_ution.nil?
    
    return rtn
  end
  
  
  # Copies all the values from 'other' to self
  def copy_values_from(other)
    self.name = other.name
    self.contributor = other.contributor
    self.share_mode = other.share_mode
    self.update_mode = other.update_mode
  end
  
  
  # Deletes all User permissions - used in application.rb::update_policy()
  def delete_all_user_permissions
    self.permissions.each do |p|
      if p.contributor_type == 'User'
        p.destroy
      end
    end
  end
  
private

  # categorize action names here (make sure you include each one as an 
  # xxx_public and xxx_protected column in ++policies++ and an xxx 
  # column in ++permissions+)
  @@categories = { "download" => ["download", 
                                  "named_download", 
                                  "submit_job",
                                  "launch"], 
                   "edit" =>     ["new", 
                                  "create", 
                                  "edit", 
                                  "update", 
                                  "new_version", 
                                  "create_version", 
                                  "destroy_version", 
                                  "edit_version", 
                                  "update_version",
                                  "new_item",
                                  "create_item", 
                                  "edit_item",
                                  "update_item",
                                  "quick_add",
                                  "resolve_link",
                                  "process_tag_suggestions"], 
                   "view" =>     ["index", 
                                  "show",
                                  "statistics",
                                  "search", 
                                  "favourite",
                                  "favourite_delete",
                                  "comment", 
                                  "comment_delete", 
                                  "rate", 
                                  "tag", 
                                  "tag_suggestions",
                                  "view", 
                                  "comments_timeline", 
                                  "comments",
                                  "items"],
                   "owner" =>    ["destroy",
                                  "destroy_item"] } # you don't need a boolean column for this but you do need to categorize 'owner only' actions!
  
  # the policy class contains a hash table of action (method) names and their categories
  # all methods are one of the three categories: download, edit and view
  def categorize(action_name)
    @@categories.each do |key, value|
      return key if value.include? action_name
    end
      
    return nil
  end
  
  def public?(category)
    attributes["#{category}_public"] == true
  end
  
  def protected?(category)
    attributes["#{category}_protected"] == true
  end
  
  def all_permissions_for_contributor(contrib)
    # call recursive method
    found = []
    find_all_permissions!(contrib, found)
    
    # split all permissions into individual and group permissions
    individual_perms = []
    group_perms = []
    found.each do |p|
      if p.contributor_type == "User"
        individual_perms << p
      elsif p.contributor_type == "Network"
        group_perms << p
      end
    end
    
    return [individual_perms, group_perms]
  end
  
  def find_all_permissions!(contrib, found)
    perm = permission?(contrib)
    found << perm unless perm.nil?
    
    case contrib.class.to_s
    when "User"
      # test networks that user is a member of
      contrib.networks.each do |n| 
        find_all_permissions!(n, found)
      end
      
      # test networks owned by user
      contrib.networks_owned.each do |n|
        find_all_permissions!(n, found)
      end
    when "Network"
      # network related tests
      # (no more specific permissions can be found when contributor is of "Network" type)
    else
      # do nothing!
    end
  end
  
  def permission?(contrib)
    p = Permission.find(:first, 
                            :conditions => ["policy_id = ? AND contributor_id = ? AND contributor_type = ?", 
                                            self.id, contrib.id, contrib.class.to_s])
    
    # will return a permission object or 'nil' if nothing found
    return p
  end
end
