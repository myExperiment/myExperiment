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
require 'scufl/dot'

class Workflow < ActiveRecord::Base
  has_many :citations, 
           :order => "created_at DESC",
           :dependent => :destroy
  
  acts_as_contributable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  acts_as_reviewable

  explicit_versioning(:version_column => "current_version", :file_columns => ["image", "svg"], :white_list_columns => ["body"]) do
    file_column :image, :magick => {
      :versions => {
        :thumb    => { :size => "100x100!" }, 
        :medium   => { :size => "500x500>" },
        :full     => { }
      }
    }
  
    file_column :svg
    
    format_attribute :body
  end
  
  #non_versioned_fields.push("image", "svg", "license", "tag_list") # acts_as_versioned and file_column don't get on
  non_versioned_columns.push("license", "tag_list", "body_html")
  
# acts_as_solr(:fields => [ :title, :body, :tag_list, :contributor_name, { :rating => :integer } ],

  acts_as_solr(:fields => [ :title, :body, :tag_list, :contributor_name ],
               :include => [ :comments ]) if SOLR_ENABLE

  acts_as_runnable
  
  validates_presence_of :title, :scufl
  
  format_attribute :body
  
  validates_uniqueness_of :unique_name
  
  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]

  file_column :image, :magick => {
    :versions => {
      :thumb    => { :size => "100x100!" }, 
      :medium   => { :size => "500x500>" },
      :full     => { },
      :padlock => { :transformation => Proc.new { |image| image.resize(100, 100).blur_image.composite(Magick::ImageList.new("#{RAILS_ROOT}/public/images/padlock.gif"), 
                                                                                                      Magick::SouthEastGravity, 
                                                                                                      Magick::OverCompositeOp) } }
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
  
  # Begin SCUFL specific methods

  def get_input_ports(version)
    return nil unless (workflow_version = self.find_version(version))
    parser = Scufl::Parser.new
    model  = parser.parse(workflow_version.scufl)
    
    return model.sources
  end
  
  def get_sculf_model(version)
    return nil unless (workflow_version = self.find_version(version))
    parser = Scufl::Parser.new
    model  = parser.parse(workflow_version.scufl)
    
    return model
  end

  # End SCUFL specific methods
end
