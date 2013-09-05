# myExperiment: app/models/pack_contributable_entry.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackContributableEntry < ActiveRecord::Base
  belongs_to :pack
  validates_presence_of :pack
  
  belongs_to :contributable, :polymorphic => true
  validates_presence_of :contributable
  
  belongs_to :user
  validates_presence_of :user
  
  before_create :check_unique
  
  before_save :check_version
  
  after_save :touch_pack
  after_destroy :touch_pack

  after_save :synchronize_research_object

  has_one :resource, :as => :context, :dependent => :destroy

  def check_unique

    conditions = ["pack_id = ?", "version = ?", "contributable_type = ?", "contributable_id = ?"]
    arguments = [self.pack_id, self.version, self.contributable_type, self.contributable_id]
    
    if self.contributable_version.nil?
      conditions << "contributable_version IS NULL"
    else
      conditions << "contributable_version = ?"
      arguments << self.contributable_version
    end

    if self.version.nil?
      conditions << "version IS NULL"
    else
      conditions << "version = ?"
      arguments << self.version
    end

    i = PackContributableEntry.find(:first, :conditions => [conditions.join(" AND ")] + arguments) 
 
    if i
      errors.add_to_base("This item already exists in the pack")
      return false
    else
      return true
    end
  end
  
  def check_version
    return true if self.contributable_version.blank?
    
    if self.contributable.respond_to?(:find_version)
      unless self.contributable.find_version(self.contributable_version)
        errors.add_to_base('The item version specified could not be found.')
      return false
      end
    else
      # A version has been set, but the contributable doesn't allow versioning, so error.    
      errors.add_to_base('The item version specified could not be found.')
      return false
    end
  end
  
  # This method gets the specific version referred to (if 'contributable_version' is set).
  # - Returns nil if cannot find the specified version.
  # - Returns the contributable version object if specified version is found (BUT NOTE this object is not a 'contributable' itself and thus cannot be treated as such).
  # - Returns the contributable object if no contributable_version is set.
  def get_contributable_version
    if self.contributable_version.blank?
      return self.contributable
    else
      if self.contributable.respond_to?(:find_version)
        return self.contributable.find_version(self.contributable_version)
      else
        return nil
      end
    end
  end
  
  def available?
    return (self.contributable != nil)
  end

  def item_as_list
    return [get_contributable_version]
  end

  def touch_pack
    pack.touch unless (pack.destroyed? || pack.contribution.nil?)
  end

  def synchronize_research_object

    ro = pack.research_object
    
    user_path = "/users/#{user_id}"

    if ro && resource.nil?

      case contributable
      when Workflow
        data = contributable.content_blob.data
        path = contributable.unique_name + (contributable.file_ext ? ".#{contributable.file_ext}" : "") 
      when Blob
        data = contributable.content_blob.data
        path = contributable.local_name
      end

      resource = ro.create_aggregated_resource(
          :user_uri     => user_path,
          :path         => path,  # FIXME - where should these be URL encoded?
          :data         => data,
          :context      => self,
          :content_type => contributable.content_type.mime_type)

      ro.update_manifest!
    end
  end
end
