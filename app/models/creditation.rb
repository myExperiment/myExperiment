# myExperiment: app/models/creditation.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Creditation < ActiveRecord::Base
  belongs_to :creditor, :polymorphic => true
  belongs_to :creditable, :polymorphic => true
end
