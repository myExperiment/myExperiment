require 'acts_as_site_entity'
require 'acts_as_contributable'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'
require 'explicit_versioning'
require 'acts_as_reviewable'
require 'acts_as_runnable'

require 'scufl/model'
require 'scufl/parser'

class TopicTagMap < ActiveRecord::Base
  set_table_name "topic_tag_map"
  
  attr_accessible :probability

  belongs_to :topic
  validates_presence_of :topic
  
  belongs_to :tag
  validates_presence_of :tag
  
  def self.probability_ordered_tags
	self.find(
	  :all,
	  :order => 'topic_tag_map.probability DESC')
  end
end