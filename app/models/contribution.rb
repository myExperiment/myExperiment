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

class Contribution < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :contributable, :polymorphic => true
  belongs_to :policy
  
  has_many :downloads
  has_many :viewings
  
  # is c_utor authorized to edit the policy for this contribution
  def admin?(c_utor)
    #policy.contributor_id.to_i == c_utor.id.to_i and policy.contributor_type.to_s == c_utor.class.to_s
    policy.admin?(c_utor)
  end
  
  # is c_utor authorized to perform action_name (using the policy)
  def authorized?(action_name, c_utor=nil)
    policy.nil? ? true : policy.authorized?(action_name, self, c_utor)
  end
  
  # is c_utor the owner of this contribution
  def owner?(c_utor)
    #contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
    
    case self.contributor_type.to_s
    when "User"
      return (self.contributor_id.to_i == c_utor.id.to_i and self.contributor_type.to_s == c_utor.class.to_s)
    when "Network"
      return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s
    else
      return false
    end
    
    #return (self.contributor_id.to_i == c_utor.id.to_i and self.contributor_type.to_s == c_utor.class.to_s) if self.contributor_type.to_s == "User"
    #return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s == "Network"
    
    #false
  end
  
  # is c_utor the uploader of this contribution
  def uploader?(c_utor)
    #contributable.contributor_id.to_i == c_utor.id.to_i and contributable.contributor_type.to_s == c_utor.class.to_s
    contributable.uploader?(c_utor)
  end
end
