# myExperiment: app/models/pack_version.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'has_research_object'

class PackVersion < ActiveRecord::Base

  validates_presence_of :title

  belongs_to :pack
  belongs_to :contributor, :polymorphic => true

  format_attribute :description

  has_many :contributable_entries,
           :class_name => "PackContributableEntry",
           :dependent => :destroy,
           :finder_sql =>
              'SELECT *
               FROM pack_contributable_entries
               WHERE pack_id = #{pack_id} AND version = #{version}
               ORDER BY created_at DESC'
  
  has_many :remote_entries,
           :class_name => "PackRemoteEntry",
           :dependent => :destroy,
           :finder_sql =>
              'SELECT *
               FROM pack_remote_entries
               WHERE pack_id = #{pack_id} AND version = #{version}
               ORDER BY created_at DESC'

  has_research_object

  acts_as_doi_mintable('pack', 'Collection')

  def items_count
    contributable_entries.count + remote_entries.count
  end
  
  def versioned_resource
    pack
  end

  def items_count
    return contributable_entries.count + remote_entries.count
  end

  def contributables
    contributable_entries.map do |e| e.contributable end
  end
  
end

