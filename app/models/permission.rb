# myExperiment: app/models/permission.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Permission < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :policy
  
  validates_presence_of :contributor
  validates_presence_of :policy
  
  validates_each :contributor do |record, attr, value|
    #record.errors.add attr, 'already owner of parent policy (has full privileges)' if value.id.to_i == record.policy.contributor.id.to_i and value.class.to_s == record.policy.contributor.class.to_s
    record.errors.add attr, 'already owner of parent policy (has full privileges)' if record.policy.admin?(value)
  end
end
