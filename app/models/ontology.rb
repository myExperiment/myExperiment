# myExperiment: app/models/ontology.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class Ontology < ActiveRecord::Base

  belongs_to :user

  has_many :predicates, :foreign_key => :ontology_id

  format_attribute(:description)

  validates_presence_of(:uri, :title, :prefix)

  validates_uniqueness_of(:uri, :prefix)

  def label
    title
  end
end

