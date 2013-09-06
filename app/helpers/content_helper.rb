# myExperiment: app/helpers/content_helper.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

module ContentHelper
  def filter_sets(objects)
    size = Conf.initial_filter_size
    sets = []

    objects.each_index do |i|

      object  = objects[i]
      visible = (i < size) || object[:selected]

      if sets.empty? || sets.last[1] != visible
        sets << [[object], visible]
      else
        sets.last[0] << object
      end
    end

    sets
  end
end

