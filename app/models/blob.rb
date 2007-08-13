require 'acts_as_contributable'

class Blob < ActiveRecord::Base
  acts_as_contributable
  
  acts_as_ferret :fields => [ :local_name, :content_type ]
end
