# myExperiment: app/models/taverna_enactor.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class TavernaEnactor < ActiveRecord::Base
  acts_as_runnable
end
