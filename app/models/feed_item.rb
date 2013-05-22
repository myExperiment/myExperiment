# myExperiment: app/models/feed_item.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class FeedItem < ActiveRecord::Base
  belongs_to :feed
  has_many :activities, :as => :objekt
end

