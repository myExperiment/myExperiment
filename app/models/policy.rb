class Policy < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  has_many :contributions
  has_many :permissions
  
  validates_presence_of :contributor
  
  def authorized?(action_name, contribution, contributor=nil)
    begin
      # false unless correct policy for contribution
      return false unless contribution.policy.id.to_i == id.to_i
      
      # false unless action can be categorized
      return false unless category = categorize(action_name)
      
      # true if policy[category_public]
      return true if public?(category)
      
      unless contributor.nil?
        # true if owner of contribution
        return true if owner?(contribution, contributor) or admin?(contribution, contributor)
      
        # true if contribution.contributor and contributor are related and policy[category_protected]
        return true if contribution.contributor.related? contributor and protected?(category)
      
        # true if permission and permission[category]
        return true if private?(category, contributor)
      end
    rescue ActiveRecord::RecordNotFound
      # all errors return false
      return false
    else
      # all failures return false
      return false
    end
  end
  
private

  # categorize action names here (make sure you include each one as an 
  # xxx_public and xxx_protected column in ++policies++ and an xxx 
  # column in ++permissions+)
  @@categories = { "download" => ["download"], 
                   "edit" => ["edit"], 
                   "view" => ["index", "show"] }
  
  # the policy class contains a hash table of action (method) names and their categories
  # all methods are one of the three categories: download, edit and view
  def categorize(action_name)
    @@categories.each do |key, value|
      return key if value.include? action_name
    end
      
    return nil
  end
  
  def owner?(c_bution, c_utor)
    c_bution.contributor_id.to_i == c_utor.id.to_i and c_bution.contributor_type.to_s == c_utor.class.to_s
  end
  
  def admin?(c_bution, c_utor)
    c_bution.policy.contributor_id.to_i == c_utor.id.to_i and c_bution.policy.contributor_type.to_s == c_utor.class.to_s
  end
  
  def public?(category)
    attributes["#{category}_public"] == true
  end
  
  def protected?(category)
    attributes["#{category}_protected"] == true
  end
  
  def private?(category, contrib)
    begin
      p = Permission.find_by_policy_id_and_contributor(id, contrib)
      
      p.attributes["#{category}"] == true
    rescue ActiveRecord::RecordNotFound
      return false
    else
      return false
    end
  end
end