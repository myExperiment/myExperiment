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


class Project < ActiveRecord::Base
  has_one :forum, :as => :owner, :dependent => :destroy
  
  has_many :users, :through => :memberships
  
  belongs_to :user
  
  has_many :memberships
  has_many :todos
  
  has_many :sharing_projects
  
  acts_as_ferret :fields => [ :title ]
  
  acts_as_pageable

  validates_format_of :unique, :with => /\A([a-z_-][a-z0-9_-]+|[0-9]+[a-z_-][a-z0-9_-])\Z/i, :if => :allow_validation,
                      :message => 'must be letters, numbers, underscores and dashes only'
  validates_uniqueness_of :unique, :allow_nil => true
  validates_presence_of :title

  def member?(user)
    self.users.include? user
  end
  
  def allow_validation
    unique != nil
  end
end
