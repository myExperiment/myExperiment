# myExperiment: app/models/concept_relation.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class ConceptRelation < ActiveRecord::Base
  belongs_to :subject_concept, :class_name => "Concept", :foreign_key => :subject_concept_id
  belongs_to :object_concept,  :class_name => "Concept", :foreign_key => :object_concept_id
end

