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

require 'acts_as_contributable'

class Workflow < ActiveRecord::Base
  acts_as_contributable
  
  acts_as_versioned
  
  acts_as_ferret :fields => { :title => { :store => :yes }, 
                              :description => { :store => :yes }, 
                              :tag_list => { :store => :yes },
                              :rating => { :index => :untokenized } }
  
  validates_presence_of :title, :scufl
  
  validates_uniqueness_of :unique

  file_column :image, :magick => {
    :versions => {
      :thumb    => { :size => "100x100!" }, 
      :medium   => { :size => "650x300>" },
      :padlock => { :transformation => Proc.new { |image| image.resize(100, 100).composite(Magick::ImageList.new("#{RAILS_ROOT}/public/images/padlock.gif"), 
                                                                                           Magick::SouthEastGravity, 
                                                                                           Magick::OverCompositeOp) } }
    }
  }
  
  non_versioned_fields.push("image") # acts_as_versioned and file_column don't get on
end
