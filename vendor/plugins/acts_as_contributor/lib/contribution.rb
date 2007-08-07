class Contribution < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :contributable, :polymorphic => true
  belongs_to :policy
  
  validates_presence_of :contributor
  validates_presence_of :contributable
  
  def authorized?(contributor, action_name)
    policy.nil? ? true : policy.authorized?(contributor, self, action_name)
  end
end