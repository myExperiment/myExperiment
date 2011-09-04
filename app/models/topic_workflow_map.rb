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

class TopicWorkflowMap < ActiveRecord::Base
  set_table_name "topic_workflow_map"  
  
  belongs_to :topic
  validates_presence_of :topic
  
  belongs_to :workflow
  validates_presence_of :workflow
end