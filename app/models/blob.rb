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
  
  acts_as_solr(:fields => [:title, :local_name, :body, :content_type, :uploader],
               :include => [ :comments ]) if SOLR_ENABLE
  belongs_to :content_blob

  # :dependent => :destroy is not supported in belongs_to in rails 1.2.6
  after_destroy { |b| b.content_blob.destroy }

  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]
  
  format_attribute :body
end
