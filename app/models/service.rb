# myExperiment: app/models/service.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'lib/acts_as_site_entity'
require 'lib/acts_as_contributable'

class Service < ActiveRecord::Base
  acts_as_site_entity
  acts_as_contributable
  acts_as_structured_data

  acts_as_solr(:fields => [ :submitter_label, :name, :provider_label, :endpoint,
      :wsdl, :city, :country, :description, :extra_search_terms ]) if Conf.solr_enable

  def extra_search_terms
    service_categories.map do |category| category.label end +
    service_tags.map do |tag| tag.label end +
    service_types.map do |types| types.label end
  end
end
