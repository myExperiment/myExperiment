# myExperiment: app/models/relationship.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class Relationship < ActiveRecord::Base

  acts_as_structured_data

  validates_presence_of(:subject)
  validates_presence_of(:predicate)
  validates_presence_of(:objekt)
  validates_presence_of(:context)

  validates_uniqueness_of :predicate_id, :scope => [:subject_id, :objekt_id]

  after_save :touch_context
  after_destroy :touch_context

  def touch_context
    # Rails 2 - use context.destroyed? instead of context.contribution.nil?
    context.touch if !context.contribution.nil? && context.respond_to?(:touch)
  end
end

