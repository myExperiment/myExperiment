class Policy < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  
  has_many :contributions,
           :dependent => :nullify
  
  has_many :permissions,
           :dependent => :destroy
  
  validates_presence_of :contributor
  
  def authorized?(action_name, contribution, contributor=nil)
    begin
      # false unless correct policy for contribution
      return false unless contribution.policy.id.to_i == id.to_i
      
      # false unless action can be categorized
      return false unless category = categorize(action_name)
      
      unless contributor.nil?
        # true if owner of contribution or administrator of contribution.policy
        return true if contribution.owner?(contributor) or contribution.admin?(contributor)
        
        # true if permission and permission[category]
        private = private?(category, contributor)
        return private unless private.nil?
        
        # true if contribution.contributor and contributor are related and policy[category_protected]
        return protected?(category) if contribution.contributor.related? contributor
      end
      
      # true if policy[category_public]
      return public?(category)
    rescue
      # all errors return false
      return false
    else
      # end of method
      return false
    end
  end
  
private

  # categorize action names here (make sure you include each one as an 
  # xxx_public and xxx_protected column in ++policies++ and an xxx 
  # column in ++permissions+)
  @@categories = { "download" => ["download"], 
                   "edit" => ["edit"], 
                   "view" => ["index", "show", "diagram", "thumbnail"] }
  
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
    begin
      if (p = Permission.find_by_policy_id_and_contributor_id_and_contributor_type(id, contrib.id, contrib.class.to_s))
        return p.attributes["#{category}"] == true
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    else
      return nil
    end
  end
end