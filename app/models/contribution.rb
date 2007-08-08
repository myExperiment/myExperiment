class Contribution < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :contributable, :polymorphic => true
  belongs_to :policy
  
  def authorized?(action_name, contributor=nil)
    policy.nil? ? true : policy.authorized?(action_name, self, contributor)
  end
end