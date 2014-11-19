# myExperiment: app/models/user_report.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class UserReport < ActiveRecord::Base

  attr_accessible :user, :subject

  belongs_to :user
  belongs_to :subject, :polymorphic => true

end
