# myExperiment: app/helpers/maps_helper.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

module MapsHelper

  def threshold_colour(threshold)

    colour = threshold.colour[2..-1]

    if colour.length == 6
      if colour.match(/^[0-9a-f]*$/)
        return "##{colour}"
      end
    end

    nil
  end

end

