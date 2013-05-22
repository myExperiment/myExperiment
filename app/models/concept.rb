# myExperiment: app/models/concept.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class Concept < ActiveRecord::Base

  belongs_to :vocabulary

  has_many :broader_relations,  :foreign_key => :object_concept_id,
                                :conditions  => "relation_type = 'broader'",
                                :class_name  => "ConceptRelation"

  has_many :broader_concepts,   :through     => :broader_relations,
                                :source      => :object_concept,
                                :class_name  => "Concept"

  has_many :narrower_relations, :foreign_key => :subject_concept_id,
                                :conditions  => "relation_type = 'broader'",
                                :class_name  => "ConceptRelation"

  has_many :narrower_concepts,  :through     => :narrower_relations,
                                :source      => :subject_concept,
                                :class_name  => "Concept"

  has_many :related_relations,  :foreign_key => :subject_concept_id,
                                :conditions  => "relation_type = 'related'",
                                :class_name  => "ConceptRelation"

  has_many :related_concepts,   :through     => :related_relations,
                                :source      => :object_concept,
                                :class_name  => "Concept"

  has_many :labels, :dependent => :destroy

  has_many :preferred_labels, :foreign_key => :concept_id,
                              :dependent   => :destroy,
                              :conditions  => "label_type = 'preferred'",
                              :class_name  => "Label"

  has_many :alternate_labels, :foreign_key => :concept_id,
                              :dependent   => :destroy,
                              :conditions  => "label_type = 'alternate'",
                              :class_name  => "Label"

  has_many :hidden_labels,    :foreign_key => :concept_id,
                              :dependent   => :destroy,
                              :conditions  => "label_type = 'hidden'",
                              :class_name  => "Label"

  format_attribute :description

  def preferred_label
    preferred_labels.first
  end

end

