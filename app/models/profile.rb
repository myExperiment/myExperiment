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

class Profile < ActiveRecord::Base
  validates_associated :owner, :picture
  
  validates_presence_of :user_id
  
  validates_format_of :website, :with => /^http:\/\//, :message => "must begin with http://", :if => Proc.new { |profile| !profile.website.nil? and !profile.website.empty? }
  
  validates_each :picture_id do |record, attr, value|
    # picture_id = nil  => null avatar
    #              n    => Picture.find(n)
    unless value.nil? or value.to_i == 0
      begin
        p = Picture.find(value)
      
        record.errors.add attr, 'invalid image (not owned)' if p.user_id.to_i != record.user_id.to_i
      rescue ActiveRecord::RecordNotFound
        record.errors.add attr, "invalid image (doesn't exist)"
      end
    end
  end
  
  format_attribute :body
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  belongs_to :picture
  
  def avatar?
    not (picture_id.nil? or picture_id.zero?)
  end
  
  def location
    if (location_city.nil? or location_city.empty?) and (location_country.nil? or location_country.empty?)
      return nil
    elsif (location_city.nil? or location_city.empty?) or (location_country.nil? or location_country.empty?)
      return location_city unless location_city.nil? or location_city.empty?
      return location_country unless location_country.nil? or location_country.empty?
    else
      return "#{location_city}, #{location_country}"
    end
  end
end
