class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  
  # added by Mark Borkum (mib104@ecs.soton.ac.uk)
  belongs_to :user
end
