#/ myExperiment: app/models/pack_remote_entry.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackRemoteEntry < ActiveRecord::Base
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

  belongs_to :resource, :dependent => :destroy

  def check_unique
    if PackRemoteEntry.find(:first, :conditions => ["pack_id = ? AND version = ? AND uri = ?", self.pack_id, self.version, self.uri])
      errors.add_to_base("This external link already exists in the pack")
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

    if ro && resource_id.nil?

      resource = ro.create_proxy(
          :proxy_for_path => uri,
          :proxy_in_path  => ".",
          :user_uri       => user_path)

      update_attribute(:resource_id, resource.id)

      ro.update_manifest!
    end
  end
end
