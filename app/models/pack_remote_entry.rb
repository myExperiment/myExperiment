#/ myExperiment: app/models/pack_remote_entry.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'has_research_object'

class PackRemoteEntry < ActiveRecord::Base

  attr_accessible :user, :pack, :title, :uri, :alternate_uri, :comment

  belongs_to :pack
  validates_presence_of :pack
  
  validates_presence_of :title, :message => " cannot be blank (see 'Title' field to fix this)"
  validates_presence_of :uri, :message => " cannot be blank (see 'Link' field to fix this)"
  
  belongs_to :user
  validates_presence_of :user  
  
  before_create :check_unique
  
  after_save :touch_pack
  after_destroy :touch_pack

  after_save :synchronize_research_object

  has_resource

  def check_unique
    if PackRemoteEntry.find(:first, :conditions => ["pack_id = ? AND version = ? AND uri = ?", self.pack_id, self.version, self.uri])
      errors.add(:base, "This external link already exists in the pack")
      return false
    else
      return true
    end
  end

  def touch_pack
    pack.touch unless (pack.destroyed? || pack.contribution.nil?)
  end

  def available?
    true
  end

  def synchronize_research_object

    ro = pack.research_object
    
    user_path = "/users/#{user_id}"

    if ro && resource.nil?

      resource = ro.create_proxy(
          :proxy_for_path => uri,
          :proxy_in_path  => ".",
          :context        => self,
          :user_uri       => user_path)

      ro.update_manifest!
    end
  end
end
