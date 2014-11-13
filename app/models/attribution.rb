# myExperiment: app/models/attribution.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Attribution < ActiveRecord::Base
  belongs_to :attributor, :polymorphic => true
  belongs_to :attributable, :polymorphic => true

  attr_accessible :attributor_type, :attributor_id, :attributable_type, :attributable_id
end
