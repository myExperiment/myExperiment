# myExperiment: app/models/blob.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'
require 'acts_as_site_entity'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'

class Blob < ActiveRecord::Base

  acts_as_site_entity :owner_text => 'Uploader'

  acts_as_contributable

  acts_as_bookmarkable
  acts_as_commentable
  acts_as_rateable
  acts_as_taggable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  acts_as_solr(:fields => [:title, :local_name, :body, :type, :uploader],
               :include => [ :comments ]) if Conf.solr_enable

  belongs_to :content_blob
  belongs_to :content_type

  # :dependent => :destroy is not supported in belongs_to in rails 1.2.6
  after_destroy { |b| b.content_blob.destroy }

  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]
  
  validates_presence_of :content_blob
  validates_presence_of :content_type

  format_attribute :body

  def type
    content_type.title
  end
end
