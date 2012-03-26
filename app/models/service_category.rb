# myExperiment: app/models/service_category.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class ServiceCategory < ActiveRecord::Base
  belongs_to :service
end

