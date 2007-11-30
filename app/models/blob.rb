# myExperiment: app/models/blob.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'
require 'acts_as_contributable'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'

class Blob < ActiveRecord::Base
  acts_as_contributable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  acts_as_ferret :fields => { :title => { :store => :yes },
                              :local_name => { :store => :yes },
                              :body => { :store => :yes },
                              :content_type => { :store => :yes } }
  
  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]
  
  format_attribute :body
end
