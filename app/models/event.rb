# myExperiment: app/models/event.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class Event < ActiveRecord::Base

  belongs_to :subject, :polymorphic => true
  belongs_to :objekt,  :polymorphic => true

  validates_presence_of :subject
  validates_presence_of :action
  validates_presence_of :subject_label
  
  before_validation do |e|

    if e.subject && e.subject_label.nil?
      e.subject_label = e.subject.label if e.subject.respond_to?(:label)
      e.subject_label = e.subject.title if e.subject.respond_to?(:title)
      e.subject_label = e.subject.name  if e.subject.respond_to?(:name)
    end

    if e.objekt && e.objekt_label.nil?
      e.objekt_label = e.objekt.label if e.objekt.respond_to?(:label)
      e.objekt_label = e.objekt.title if e.objekt.respond_to?(:title)
      e.objekt_label = e.objekt.name  if e.objekt.respond_to?(:name)
    end
  end
end

