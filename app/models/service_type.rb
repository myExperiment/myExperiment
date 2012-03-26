# myExperiment: app/models/service_type.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class ServiceType < ActiveRecord::Base
  belongs_to :service
end

