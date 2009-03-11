# myExperiment: app/models/workflow.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'
require 'acts_as_contributable'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'
require 'explicit_versioning'
require 'acts_as_reviewable'
require 'acts_as_runnable'

require 'scufl/model'
require 'scufl/parser'

class Workflow < ActiveRecord::Base
  
  has_many :citations, 
           :order => "created_at DESC",
           :dependent => :destroy

  belongs_to :content_blob
  
  # need to destroy the workflow versions and their content blobs to avoid orphaned records
  before_destroy { |w| w.versions.each do |wv|
                        wv.content_blob.destroy if wv.content_blob
                        wv.destroy
                      end }

  acts_as_contributable
  
  acts_as_bookmarkable
  acts_as_commentable
  acts_as_rateable
  acts_as_taggable

  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  acts_as_reviewable

  explicit_versioning(:version_column => "current_version", 
                      :file_columns => ["image", "svg"], 
                      :white_list_columns => ["body"]) do
    
    file_column :image, :magick => {
      :versions => {
        :thumb    => { :size => "100x100" }, 
        :medium   => { :size => "500x500>" },
        :full     => { }
      }
    }
  
    file_column :svg
    
    format_attribute :body
    
    belongs_to :content_blob
    
    # :dependent => :destroy is not supported in belongs_to in rails 1.2.6
    after_destroy { |wv| wv.content_blob.destroy if wv.content_blob }
    
    # Update the parent contribution model buy only if this isn't the current version (because the workflow model will take care of that).
    # This is required to keep the contribution's updated_at field accurate.
    after_save { |wv| wv.workflow.contribution.save if wv.workflow.contribution && wv.version != wv.workflow.current_version }
    
  end
  
  #non_versioned_fields.push("image", "svg", "license", "tag_list") # acts_as_versioned and file_column don't get on
  non_versioned_columns.push("license", "tag_list", "body_html")
  
# acts_as_solr(:fields => [ :title, :body, :tag_list, :contributor_name, { :rating => :integer } ],

  acts_as_solr(:fields => [ :title, :body, :tag_list, :contributor_name, :type_display_name, :get_all_search_terms ],
               :include => [ :comments ]) if SOLR_ENABLE

  acts_as_runnable
  
  validates_presence_of :title
  
  format_attribute :body
  
  validates_presence_of :unique_name
  validates_uniqueness_of :unique_name
  
  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]
  
  validates_presence_of :content_blob
  validates_presence_of :content_type

  file_column :image, :magick => {
    :versions => {
      :thumb    => { :size => "100x100>" }, 
      :medium   => { :size => "500x500>" },
      :full     => { },
    }
  }
  
  file_column :svg
  
  def tag_list_comma
    list = ''
    tags.each do |t|
      if list == ''
        list = t.name
      else
        list += (", " + t.name)
      end
    end
    return list
  end
  
  # Sets an internal unique name for this workflow.
  def set_unique_name
    salt = rand 1000000
    salt2 = rand 100
    if self.title.blank?
      self.unique_name = "#{salt}_#{salt2}"        
    else
      self.unique_name = "#{self.title.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"
    end
  end
  
  def processor_class
    @processor_class ||= WorkflowTypesHandler.processor_class_for_content_type(self.content_type)
  end
  
  def can_infer_metadata_for_this_type?
    proc_class = self.processor_class
    return false if proc_class.nil?
    return proc_class.can_infer_metadata?
  end
  
  def type_display_name
    WorkflowTypesHandler.type_display_name_for_content_type(self.content_type)  
  end
  
  def display_data_format
    klass = self.processor_class
    @display_data_format = (klass.nil? ? self.file_ext : klass.display_data_format)
  end
  
  def get_workflow_model_object(version)
    return nil unless (workflow_version = self.find_version(version))
    return (self.processor_class.nil? ? nil : self.processor_class.new(workflow_version.content_blob.data).get_workflow_model_object)
  end
  
  def get_search_terms(version)
    return nil unless (workflow_version = self.find_version(version))
    return (self.processor_class.nil? ? nil : self.processor_class.new(workflow_version.content_blob.data).get_search_terms)
  end

  # Begin acts_as_runnable overridden methods
 
  def get_input_ports(version)
    return nil unless (workflow_version = self.find_version(version))
    return (self.processor_class.nil? ? nil : self.processor_class.new(workflow_version.content_blob.data).get_workflow_model_input_ports)
  end
  
  # End acts_as_runnable overridden methods

  def filename(version=nil)
    if version.blank?
      return "#{unique_name}.#{file_ext}"
    else
      return nil unless (workflow_version = self.find_version(version))
      return "#{workflow_version.unique_name}.#{file_ext}"
    end
  end
  
  def named_download_url
    "#{Conf.base_uri}/workflows/#{id}/download/#{filename}"
  end

  def get_all_search_terms

    words = StringIO.new

    versions.each do |version|
      words << get_search_terms(version.version)
    end

    words.rewind
    words.read
  end

  def get_tag_suggestions()

    ignore = [ "and", "the", "or", "a", "an" ]
    
    text = "#{title} #{body} #{get_search_terms(current_version)}"

    words = text.split(/[^a-zA-Z0-9]+/).uniq

    all_tags = Tag.find(:all).select do |t| t.taggings_count > 0 end.map do |t| t.name end

    candidates = words - (words - all_tags)

    candidates = candidates - ignore

    existing = tags.map do |t| t.name end

    (candidates - existing).sort
  end

  def components
    processor_class.new(content_blob.data).get_components
  end

end
