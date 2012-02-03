# myExperiment: app/models/topic_run.rb
#

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

class TopicRun < ActiveRecord::Base

  attr_accessor :desc, :runtime

  has_many :topics,
           :class_name => "Topic",
           :foreign_key => :run_id,
           :dependent => :destroy
		   
  def self.most_recent
    self.find(
	  :first,
	  :order => 'topic_runs.id DESC')
  end
		   
end
