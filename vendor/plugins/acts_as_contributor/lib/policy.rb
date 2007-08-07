class Policy < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  has_many :contributions
  has_many :permissions
  
  validates_presence_of :contributor
  
  def authorized?(contributor, contribution, action_name)
    begin
      # false unless correct policy for contribution
      return false unless contribution.policy.id.to_i == id.to_i
      
      # false unless action can be categorized
      return false unless category = categorize(action_name)
      
      # true if owner of contribution
      return true if contribution.contributor_id.to_i == contributor.id.to_i and contribution.contributor_type.to_s == contributor.type.to_s
      
      # true if policy[category_public]
      return true if attributes["#{category}_public"] == true
      
      # true if contribution.contributor and contributor are related and policy[category_protected]
      return true if contribution.contributor.related? contributor and attributes["#{category}_protected"] == true
      
      # true if permission and permission[category]
      return true if (p = Permission.find_by_policy_id_and_contributor_id_and_contributor_type(id, contributor.id, contributor.type)) and p.attributes["#{category}"] == true
    rescue
      # all errors return false
      return false
    else
      # all failures return false
      return false
    end
  end
  
private
  
  # the policy class contains a hash table of action (method) names and their categories
  # all methods are one of the three categories: download, edit and view
  def categorize(action_name)
    categories = { "download" => ["download"], 
                   "edit" => ["edit"], 
                   "view" => ["index", "show"] }
    
    categories.each do |key, value|
      return key if value.include? action_name
    end
      
    return nil
  end
end