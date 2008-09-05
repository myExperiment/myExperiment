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
  
  
  def determine_update_mode(c_ution)
    
    # return nil unless correct policy for contribution
    return nil if c_ution.nil? || !(c_ution.policy.id.to_i == id.to_i)
    
    return self.update_mode unless self.update_mode.nil?

    v_pub  = self.view_public;
    v_prot = self.view_protected;
    d_pub  = self.download_public;
    d_prot = self.download_protected;
    e_pub  = self.edit_public;
    e_prot = self.edit_protected;
    
    
    # check if permissions would allow editing for anyone at all: it happens, when permissions array 
    # isn't empty AND there are some permissions with 'edit' field set to true
    perms = self.permissions
    perms_exist = !perms.empty?


    # initializing; ..used for validation below
    my_networks    = []
    other_networks = []
    my_friends     = []
    other_users    = []
    
    # group permissions are separate from the modes, so first of all;
    # so the best thing to do is to split all permissions into different groups
    # (do this just if there are any permissions at all):
    if perms_exist #, then do the splitting
      contributor = User.find(c_ution.contributor_id)

      contributors_friends  = contributor.friends.map do |f| f.id end
      contributors_networks = (contributor.networks + contributor.networks_owned).map do |n| n.id end

      puts "contributors_networks = #{(contributors_networks.map do |n| n.id end).join(";")}"

      perms.each do |p|
        puts "contributor_id = #{p.contributor_id}; contributor_type = #{p.contributor_type}"
        case p.contributor_type
          when 'Network'
            if contributors_networks.index(p.contributor_id).nil?
              other_networks.push p
            else
              my_networks.push p
            end

          when 'User'
            if contributors_friends.index(p.contributor_id).nil?
              other_users.push p
            else
              my_friends.push p
            end
        end
      end

    end

    # DEBUG
    # puts "counts of permissions for:"
    # puts "all permissions= #{perms_exist ? perms.length : 'nil'}"
    # puts "my_networks    = #{my_networks.length}"
    # puts "other_networks = #{other_networks.length}"
    # puts "my_friends     = #{my_friends.length}"
    # puts "other_users    = #{other_users.length}"
    # END OF DEBUG

    
    # some pre-processing - check if other_users and other_networks don't have edit permissions; check if friends can't edit
    other_users_and_networks_cant_edit = ((other_networks + other_users).select do |p| p.edit end).empty?
    my_friends_cant_edit = (my_friends.select do |p| p.edit end).empty?


    # (modes 5 & 6 give the least permissions, which is the safest - so these get checked first; then mode 1; then mode 0)
    # (this is the order from most 'narrow' update permissions to the 'widest' ones) 


    # MODE 5? some of my friends (and noone else, apart from the owner & any of 'my groups' can edit)
    #
    # Conditions:
    # 1) no permissions should exist at all
    #   OR
    # 2) don't care about any permissions for 'my_groups';
    # 3) no edit permissions should exist for 'other_networks', 'other_users'
    # 4) some edit permissions should exist for 'my_friends'
         
    #  === AND === (mode 5 & mode 6 go together, as the checks are very similar)

    # MODE 6? noone else (apart from the owner & any of 'my groups' can edit)
    #
    # Conditions:
    # 1) no permissions should exist at all
    #   OR
    # 2) don't care about any permissions for 'my_groups';
    # 3) no edit permissions should exist for 'other_networks', 'other_users', 'my_friends'
    if (e_pub == false && e_prot == false)
      if !perms_exist || other_users_and_networks_cant_edit
        if my_friends_cant_edit
          return 6
        else
          return 5
        end
      end
    end


    # MODE 1? only "all friends" and "network members of my groups" can edit
    #
    # Conditions:
    # 1) no permissions should exist at all
    #   OR
    # 2) no edit permissions for 'other_networks' or 'other_users' should exist at all;
    # 3) all permissions for 'my_friends' should allow editing (if any denies, it's not this mode);
    # 4) don't care about any permissions for 'my_networks' at all. 
    if (e_pub == false && e_prot == true)
      if !perms_exist || (other_users_and_networks_cant_edit && (my_friends.select do |p| !p.edit end).empty?)
        return 1
      end
    end


    # MODE 0? same as those that can view AND download
    #
    # Conditions:
    # for all of the three types of access (public, protected and permission-based),
    # everyone who can 'view' AND 'download' should be able to 'edit' for this type of policy
    # to classify as belonging to this mode.
    # (for permission-based access, don't take into account any of 'my group' permissions) 
    if (e_pub == (v_pub && d_pub))
      if (e_prot == (v_prot && d_prot))
        # select only those elements from the arrays of permissions, for which ('view' && 'download') != 'edit'
        if ((my_friends + other_users + other_networks).select do |p| p.edit != (p.view && p.download) end).empty?
          return 0;
        end
      end
    end

    
    # MODE 7: couldn't determine the mode, so should have CUSTOM update mode
    return 7
  end
  
  
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
      
    unless c_utor.nil?
      if c_ution
        # true if owner of contribution or administrator of contribution.policy
        return true if (c_ution.owner?(c_utor) or c_ution.admin?(c_utor))
      else
        # true if administrator of self
        return true if admin?(c_utor)
      end
        
      # true if permission and permission[category]
      private = private?(category, c_utor)
      return private unless private.nil?
        
      if c_ution
        # true if contribution.contributor and contributor are related and policy[category_protected]
        return true if (c_ution.contributor.protected? c_utor and protected?(category))
      else
        # true if policy.contributor and contributor are related and policy[category_protected]
        return true if (self.contributor.protected? c_utor and protected?(category))
      end
    end
      
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
                     :view_public => true,         # anonymous can view
                     :download_public => true,     # anonymous can download
                     :edit_public => false,        # anonymous can't edit
                     :view_protected => true,      # friends can view
                     :download_protected => true,  # friends can download
                     :edit_protected => false,     # friends can't edit
                     :share_mode => 0,
                     :update_mode => 6)     
                     
    c_ution.policy = rtn unless c_ution.nil?
    
    return rtn
  end
  
  
  # Copies all the values from 'other' to self
  def copy_values_from(other)
    self.name = other.name
    self.contributor = other.contributor
    self.view_public = other.view_public
    self.download_public = other.download_public
    self.edit_public = other.edit_public
    self.view_protected = other.view_protected
    self.download_protected = other.download_protected
    self.edit_protected = other.edit_protected
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
                                  "resolve_link"], 
                   "view" =>     ["index", 
                                  "show", 
                                  "search", 
                                  "favourite",
                                  "favourite_delete",
                                  "comment", 
                                  "comment_delete", 
                                  "rate", 
                                  "tag", 
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
  
  def private?(category, contrib)
    found = []
    
    # call recursive method
    private!(category, contrib, found)
    
    unless found.empty?
      rtn = nil
      
      found.each do |f|
        id, type, result = f[0], f[1], f[2]
        
        case type.to_s
        when "User"
          return result
        when "Network"
          if rtn.nil?
            rtn = result
          else
            rtn = result if result == true
          end
        else
          # do nothing!
        end
      end
      
      return rtn
    else
      return nil
    end
  end
  
  def private!(category, contrib, found)
    result = permission?(category, contrib)
    found << [contrib.id, contrib.class.to_s, result] unless result.nil?
    
    case contrib.class.to_s
    when "User"
      contrib.networks.each do |n| # test networks that user is a member of 
        private!(category, n, found)
      end
      
      contrib.networks_owned.each do |n| # test networks owned by user
        private!(category, n, found)
      end
    when "Network"
      # network related tests
    else
      # do nothing!
    end
  end
  
  def permission?(category, contrib)
    if (p = Permission.find(:first, 
                            :conditions => ["policy_id = ? AND contributor_id = ? AND contributor_type = ?", 
                                            self.id, contrib.id, contrib.class.to_s]))
      return p.attributes["#{category}"]
    else
      return nil
    end
  end
end
