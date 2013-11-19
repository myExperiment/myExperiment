# myExperiment: app/models/activity.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'securerandom'

class Activity < ActiveRecord::Base

  belongs_to :subject, :polymorphic => true
  belongs_to :objekt,  :polymorphic => true
  belongs_to :context, :polymorphic => true
  belongs_to :auth,    :polymorphic => true

  has_many :comments, :as => :commentable, :dependent => :destroy

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

    if e.objekt && (e.objekt_label.nil? || e.objekt_label == "") && e.auth
      e.objekt_label = e.auth.label if e.auth.respond_to?(:label)
      e.objekt_label = e.auth.title if e.auth.respond_to?(:title)
      e.objekt_label = e.auth.name  if e.auth.respond_to?(:name)
    end
  end

  def self.new_activities(opts)

    subject   = opts[:subject]
    action    = opts[:action]
    object    = opts[:object]
    timestamp = opts[:timestamp]
    auth      = nil
    extra     = opts[:extra]
    contexts  = [subject]
    priority  = 0

    return [] if opts[:auth].kind_of?(Activity)

    # Set the timestamp to the current time if no timestamp was provided.

    timestamp = Time.now if timestamp.nil?

    case object.class.name

      when "Workflow", "Blob", "Pack"

        contexts << object
        auth = object
        
        priority = 100 if action == 'create'

      when "WorkflowVersion", "BlobVersion"

        contexts << object.versioned_resource
        extra = object.version
        auth = object.versioned_resource

        priority = 50 if action == 'create'

      when "Comment"

        contexts << object.commentable
        auth = object.commentable

      when "Bookmark"

        contexts << object.bookmarkable
        auth = object.bookmarkable

      when "Citation"

        contexts << object.workflow
        auth = object.workflow

      when "Rating"

        contexts << object.rateable
        auth = object.rateable
        extra = object.rating

      when "Review"

        contexts << object.reviewable
        auth = object.reviewable

      when "Tagging"

        contexts << object.taggable
        auth = object.taggable
        extra = object.tag.name

      when "Network"

        contexts << object

        priority = 100 if action == 'create'

      when "Membership"

        contexts << object.network

      when "Permission"
 
        contexts << opts[:contributable]
        contexts << object.contributor
        auth = opts[:contributable]

      when "GroupAnnouncement"

        contexts << object.network
        extra = object.public

      when "Creditation"

        contexts << object.creditable
        contexts << object.creditor if object.creditor != subject
        auth = object.creditable

      when "FeedItem"

        auth = subject.feed.context

      when "Resource"

        contexts << object.research_object.context

        if object.is_annotation?
          object.annotation_targets.each do |target|
            if target.context
              contexts << target.context
            end
          end
        end

        auth = object

      when "Attribution"

        contexts << object.attributor
        contexts << object.attributable

    end

    uuid = SecureRandom.uuid

    contexts.map do |context|
      Activity.new(
          :subject => subject,
          :action => action,
          :objekt => object,
          :extra => extra,
          :auth => auth,
          :uuid => uuid,
          :timestamp => timestamp,
          :priority => priority,
          :context => context)
    end
  end


  def self.create_activities(opts)
    activities = self.new_activities(opts)

    activities.each do |activity|
      activity.save
    end
  end

end

