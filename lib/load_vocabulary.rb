# myExperiment: lib/load_vocabulary.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

module LoadVocabulary

  def self.load_skos(data)

    exising_vocabulary = Vocabulary.find_by_uri(data["uri"])
    exising_vocabulary.destroy if exising_vocabulary

    vocabulary = Vocabulary.create(
        :uri         => data["uri"],
        :title       => data["title"],
        :prefix      => data["prefix"],
        :description => data["description"])

    data["concepts"].each do |concept|
      
      c = Concept.create(
          :phrase      => concept["phrase"],
          :description => concept["description"])

      c.labels << Label.create(
          :vocabulary => vocabulary,
          :text       => concept["label"],
          :label_type => 'preferred',
          :language   => 'en')

      if concept["alternate"]
        concept["alternate"].each do |alternate|
          
          c.labels << Label.create(
              :vocabulary => vocabulary,
              :text       => alternate,
              :label_type => 'alternate',
              :language   => 'en')
        end
      end

      if concept["hidden"]
        concept["hidden"].each do |hidden|

          c.labels << Label.create(
              :vocabulary => vocabulary,
              :text       => hidden,
              :label_type => 'hidden',
              :language   => 'en')
        end
      end

      vocabulary.concepts << c

    end
  end

  def self.load_ontology(data)

    existing_ontology = Ontology.find_by_uri(data["uri"])
    existing_ontology.destroy if existing_ontology

    ontology = Ontology.create(
        :uri         => data["uri"],
        :title       => data["title"],
        :prefix      => data["prefix"],
        :description => data["description"])

    data["predicates"].each do |predicate|
      
      p = Predicate.create(
          :title         => predicate["title"],
          :phrase        => predicate["phrase"],
          :description   => predicate["description"],
          :equivalent_to => predicate["equivalent_to"])

      ontology.predicates << p

    end
  end
end

