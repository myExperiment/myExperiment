# myExperiment: app/helpers/application_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class TopicFeedback < ActiveRecord::Base
  belongs_to :user
  validates_inclusion_of :score, :in => [-1, 1]
end

