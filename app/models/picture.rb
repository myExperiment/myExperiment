##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##


class Picture < FlexImage::Model
  
  belongs_to :user
  
  # exception classes
  class InvalidCropRect < StandardError; end
  
  # crops the attached image according to the passed left, top, width, and height params.
  # if resize_to_stencil is true, the image is resized to stencil_w x stencil_h.
  # after cropping and resizing, the resulting image is saved back to disk.
  # any thumbnail image the image may have is automatically updated.
  def krop!( options = {} )
    # setup the default params
    options[:crop_left]   ||= 0
    options[:crop_top]    ||= 0
    options[:crop_width]  ||= 100
    options[:crop_height] ||= 100
    options[:stencil_width]  ||= 100
    options[:stencil_height] ||= 100
    options[:resize_to_stencil] ||= false
    # passed params could be strings, so convert them to ints/booleans
    crop_l = options[:crop_left].to_i
    crop_t = options[:crop_top].to_i
    crop_w = options[:crop_width].to_i
    crop_h = options[:crop_height].to_i
    stencil_w = options[:stencil_width].to_i
    stencil_h = options[:stencil_height].to_i
    resize_to_stencil = false if (options[:resize_to_stencil] == false) || (options[:resize_to_stencil] == "false")
    resize_to_stencil = true if (options[:resize_to_stencil] == true) || (options[:resize_to_stencil] == "true")
    
    if (crop_w <= 0) || (crop_h <= 0) || (crop_l + crop_w <= 0) || (crop_t + crop_h <= 0) #|| (crop_l >= data.base_columns) || (crop_t >= data.base_rows)
      raise InvalidCropRect
    end
    
    image = rmagick_image
    image.crop!(crop_l, crop_t, crop_w, crop_h, true)
    image.resize!(stencil_w, stencil_h) if resize_to_stencil
    self.rmagick_image = image
  end
  
end
