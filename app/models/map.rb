# myExperiment: app/models/map.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'
require 'acts_as_site_entity'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'

class Map < ActiveRecord::Base

  acts_as_site_entity :owner_text => 'Creator'

  acts_as_contributable

  acts_as_bookmarkable
  acts_as_commentable
  acts_as_rateable
  acts_as_taggable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  acts_as_solr(:fields => [:title, :description, :uploader, :tag_list],
               :boost => "rank",
               :include => [ :comments ]) if Conf.solr_enable

  belongs_to :license
  validates_presence_of :license_id
  validates_presence_of :title

  format_attribute :description

  def rank

    # initial boost depends on viewings count
    boost = contribution.viewings_count / 100

    # Take curation events into account
    boost += CurationEvent.curation_score(CurationEvent.find_all_by_object_type_and_object_id('Map', id))
    
    # penalty for no description
    boost -= 20 if description.nil? || description.empty?
    
    boost
  end
end

