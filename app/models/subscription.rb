# myExperiment: app/models/subscription.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :objekt, :polymorphic => true

  validates_uniqueness_of :objekt_id, :scope => [:user_id, :objekt_type]
end

