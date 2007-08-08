class Contribution < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :contributable, :polymorphic => true
  belongs_to :policy
  
  def authorized?(contributor, action_name)
    policy.nil? ? true : policy.authorized?(contributor, self, action_name)
  end
end