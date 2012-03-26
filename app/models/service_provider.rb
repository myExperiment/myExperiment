# myExperiment: app/models/service_provider.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class ServiceProvider < ActiveRecord::Base
  has_many :service_deployments, :foreign_key => :service_provider_id
end

