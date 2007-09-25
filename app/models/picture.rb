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

#class Picture < ActiveRecord::Base
class Picture < FlexImage::Model
  validates_associated :owner
  
  validates_presence_of :user_id, :data
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  has_many :profiles,
           :foreign_key => :picture_id
           
  def select!
    unless selected?
      owner.profile.update_attribute :picture_id, id
      return true
    else
      return false
    end
  end
  
  def selected?
    owner.profile.avatar? and owner.profile.picture.id.to_i == id.to_i
  end
  
  #file_column :data, :magick => {
  #  :versions => {
  #    :small    => { :size => "50x50!" }, 
  #    :medium   => { :size => "100x100!" },
  #    :large => { :size => "200x200!" }
  #  }
  #}
end
