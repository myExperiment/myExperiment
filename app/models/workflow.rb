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
require 'acts_as_contributable'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'
require 'explicit_versioning'

class Workflow < ActiveRecord::Base
  has_many :citations, 
           :order => "created_at DESC",
           :dependent => :destroy
  
  acts_as_contributable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable

  explicit_versioning(:version_column => "current_version", :file_columns => ["image", "svg"], :white_list_columns => ["body"]) do
    file_column :image, :magick => {
      :versions => {
        :thumb    => { :size => "100x100!" }, 
        :medium   => { :size => "500x500>" },
        :full     => { }
      }
    }
  
    file_column :svg
    
    format_attribute :body
  end
  
  #non_versioned_fields.push("image", "svg", "license", "tag_list") # acts_as_versioned and file_column don't get on
  non_versioned_columns.push("license", "tag_list", "body_html")
  
  acts_as_ferret :fields => { :title => { :store => :yes }, 
                              :body => { :store => :yes }, 
                              :tag_list => { :store => :yes },
                              :rating => { :index => :untokenized },
                              :contributor_name => { :store => :yes } }
  
  validates_presence_of :title, :scufl
  
  format_attribute :body
  
  validates_uniqueness_of :unique_name
  
  validates_inclusion_of :license, :in => [ "by-nd", "by-sa", "by" ]

  file_column :image, :magick => {
    :versions => {
      :thumb    => { :size => "100x100!" }, 
      :medium   => { :size => "500x500>" },
      :full     => { },
      :padlock => { :transformation => Proc.new { |image| image.resize(100, 100).blur_image.composite(Magick::ImageList.new("#{RAILS_ROOT}/public/images/padlock.gif"), 
                                                                                                      Magick::SouthEastGravity, 
                                                                                                      Magick::OverCompositeOp) } }
    }
  }
  
  file_column :svg
  
  def contributor_name
    case contribution.contributor.class.to_s
    when "User"
      return contribution.contributor.name
    when "Network"
      return contribution.contributor.title
    else
      return nil
    end
  end
  
  def tag_list_comma
    list = ''
    tags.each do |t|
      if list == ''
        list = t.name
      else
        list += (", " + t.name)
      end
    end
    return list
  end
  
end
