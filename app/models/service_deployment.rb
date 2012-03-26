# myExperiment: app/models/service_deployment.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class ServiceDeployment < ActiveRecord::Base
  belongs_to :service_provider
  belongs_to :service
end

