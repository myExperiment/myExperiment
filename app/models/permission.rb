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

class Permission < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :policy
  
  validates_presence_of :contributor
  validates_presence_of :policy
  
  validates_each :contributor do |record, attr, value|
    #record.errors.add attr, 'already owner of parent policy (has full privileges)' if value.id.to_i == record.policy.contributor.id.to_i and value.class.to_s == record.policy.contributor.class.to_s
    record.errors.add attr, 'already owner of parent policy (has full privileges)' if record.policy.admin?(value)
  end
end
