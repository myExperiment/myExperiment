# myExperiment: app/models/pack_remote_entry.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class PackRemoteEntry < ActiveRecord::Base
  belongs_to :pack
  
  belongs_to :user
end
