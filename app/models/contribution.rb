class Contribution < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :contributable, :polymorphic => true
  belongs_to :policy
  
  def authorized?(action_name, c_utor=nil)
    policy.nil? ? true : policy.authorized?(action_name, self, c_utor)
  end
  
  def owner?(c_utor)
    #contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
    
    return (self.contributor_id.to_i == c_utor.id.to_i and self.contributor_type.to_s == c_utor.class.to_s) if self.contributor_type.to_s == "User"
    return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s == "Network"
    
    false
  end
  
  def admin?(c_utor)
    policy.contributor_id.to_i == c_utor.id.to_i and policy.contributor_type.to_s == c_utor.class.to_s
  end
  
  def uploader?(c_utor)
    contributable.contributor_id.to_i == c_utor.id.to_i and contributable.contributor_type.to_s == c_utor.class.to_s
  end
end