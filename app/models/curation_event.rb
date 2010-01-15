# myExperiment: app/models/curation_event.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class CurationEvent < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :object, :polymorphic => true

  format_attribute :details

  validates_presence_of :user, :category

  def self.curation_score(events)

    score = 0

    events.each do|event|

      case event.category
        when 'example'
          score += 40
        when 'test'
          score += 0
        when 'component'
          score += 45
        when 'whole solution'
          score += 50
        when 'tutorial'
          score += 30
        when 'obsolete'
          score += 20
        when 'incomplete'
          score += 10
        when 'junk'
          score -= 50
      end
    end
      
    score
  end
end

