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
  
  def admin?(c_utor)
    return false unless c_utor
    
    contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
  end
  
  # THIS IS THE DEFAULT POLICY (see /app/views/policies/_list_form.rhtml)
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

  # categorize action names here 
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
