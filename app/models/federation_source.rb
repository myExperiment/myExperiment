# myExperiment: app/models/federation_source.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.


class FederationSource < ActiveRecord::Base
  acts_as_site_entity
  acts_as_contributor
end

