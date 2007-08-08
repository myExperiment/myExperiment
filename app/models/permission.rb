class Permission < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :policy
  
  validates_presence_of :contributor
  validates_presence_of :policy
end