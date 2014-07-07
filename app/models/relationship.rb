# myExperiment: app/models/relationship.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class Relationship < ActiveRecord::Base

  attr_accessible :user

  belongs_to :user

  belongs_to :context, :polymorphic => true

  belongs_to :subject, :polymorphic => true
  belongs_to :predicate
  belongs_to :objekt,  :polymorphic => true

  validates_presence_of(:subject)
  validates_presence_of(:predicate)
  validates_presence_of(:objekt)
  validates_presence_of(:context)

  validates_uniqueness_of :predicate_id, :scope => [:subject_id, :objekt_id]

  after_save :touch_context
  after_destroy :touch_context

  def touch_context
    context.touch unless context.destroyed?
  end
end

