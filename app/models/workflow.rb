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
  
  # need to destroy the content_blobs belonging to the workflow versions to avoid orphaned records
  before_destroy { |w| w.versions.each do |wv|
                        wv.content_blob.destroy
                      end }

  acts_as_contributable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  acts_as_reviewable

  explicit_versioning(:version_column => "current_version", :file_columns => ["image", "svg"], :white_list_columns => ["body"]#, :other_columns => ["content_blob_id"]
  ) do
    file_column :image, :magick => {
      :versions => {
        :thumb    => { :size => "100x100!" }, 
        :medium   => { :size => "500x500>" },
        :full     => { }
      }
    }
  
    file_column :svg
    
    format_attribute :body
    
    belongs_to :content_blob
    # :dependent => :destroy is not supported in belongs_to in rails 1.2.6
    after_destroy { |wv| wv.content_blob.destroy }
     
  end
  
  #non_versioned_fields.push("image", "svg", "license", "tag_list") # acts_as_versioned and file_column don't get on
  non_versioned_columns.push("license", "tag_list", "body_html")
  
# acts_as_solr(:fields => [ :title, :body, :tag_list, :contributor_name, { :rating => :integer } ],

  acts_as_solr(:fields => [ :title, :body, :tag_list, :contributor_name ],
               :include => [ :comments ]) if SOLR_ENABLE

  acts_as_runnable
  
  validates_presence_of :title
  
  format_attribute :body
  
  validates_presence_of :unique_name
  validates_uniqueness_of :unique_name
  
  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]
  
  validates_presence_of :content_type

  file_column :image, :magick => {
    :versions => {
      :thumb    => { :size => "100x100!" }, 
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
  
  # Sets an internal unique name for this workflow entry.
  # Note: only sets unique_name if not already set before
  def set_unique_name
    if self.unique_name.blank?
      salt = rand 1000000
      salt2 = rand 100
      if self.title.blank?
        self.unique_name = "#{salt2}_#{salt}"        
      else
        self.unique_name = "#{self.title.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"
      end
    end
  end
  
  # Begin SCUFL specific methods

  def get_input_ports(version)
    return nil unless (workflow_version = self.find_version(version))
    parser = Scufl::Parser.new
    model  = parser.parse(workflow_version.content_blob.data)
    
    return model.sources
  end
  
  def get_workflow_model_object(version)
    return nil unless (workflow_version = self.find_version(version))
    parser = Scufl::Parser.new
    model  = parser.parse(workflow_version.content_blob.data)
    
    return model
  end

  # End SCUFL specific methods

  def named_download_url
    "#{BASE_URI}/workflows/#{id}/download/#{unique_name}.xml"
  end

end
