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
  
  acts_as_solr(:fields => [:title, :local_name, :body, :kind, :uploader, :tag_list],
               :boost => "rank",
               :include => [ :comments ]) if Conf.solr_enable

  belongs_to :content_blob
  belongs_to :content_type
  belongs_to :license
 

  # :dependent => :destroy is not supported in belongs_to in rails 1.2.6
  after_destroy { |b| b.content_blob.destroy }

  validates_presence_of :content_blob
  validates_presence_of :content_type

  validates_presence_of :title

  format_attribute :body

  def type
    content_type.title
  end

  alias_method :kind, :type

  def rank

    # initial boost depends on viewings count
    boost = contribution.viewings_count / 100

    # Take curation events into account
    boost += CurationEvent.curation_score(CurationEvent.find_all_by_object_type_and_object_id('Blob', id))
    
    # penalty for no description
    boost -= 20 if body.nil? || body.empty?
    
    boost
  end

  def named_download_url
    "#{Conf.base_uri}/files/#{id}/download/#{local_name}"
  end
end
