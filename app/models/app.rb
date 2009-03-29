# myExperiment: app/models/app.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_site_entity'
require 'acts_as_contributable'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'

class App < ActiveRecord::Base

  acts_as_site_entity :owner_text => 'Creator'

  acts_as_contributable

  acts_as_bookmarkable
  acts_as_commentable
  acts_as_rateable
  acts_as_taggable

  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  has_many :algorithm_instances
  has_many :algorithms, :through => :algorithm_instances

  acts_as_solr(:fields => [:title, :description]) if SOLR_ENABLE

  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]
  
  format_attribute :description
end
