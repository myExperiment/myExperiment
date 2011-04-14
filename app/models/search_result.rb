# myExperiment: app/models/search_result.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class SearchResult < ActiveRecord::Base
  belongs_to(:result, :polymorphic => true)
end

