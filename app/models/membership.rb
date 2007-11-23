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

class Membership < ActiveRecord::Base
  belongs_to :user

  belongs_to :network

  validates_presence_of :user_id, :network_id

  validates_each :user_id do |model, attr, value|
    model.errors.add attr, "already member" if model.network.member? value
  end

  def user_establish!
    if self.user_established_at.nil?
      return update_attribute(:user_established_at, Time.now)
    else
      return false
    end
  end

  def network_establish!
    if self.network_established_at.nil?
      return update_attribute(:network_established_at, Time.now)
    else
      return false
    end
  end

  def accept!
    unless accepted?
      if self.user_established_at.nil?
        self.user_establish!
      end
      if self.network_established_at.nil?
        self.network_establish!
      end
      return true
    else
      return false
    end
  end

  def accepted?
    self.user_established_at != nil and self.network_established_at != nil
  end

  def accepted_at

    user_established_at    = self.user_established_at
    network_established_at = self.network_established_at

    return nil if user_established_at.nil? or network_established_at.nil?

    return user_established_at > network_established_at ? user_established_at : network_established_at;

  end
  
  def is_invite?
    if user_established_at.nil?
      return true
    elsif network_established_at.nil?
      return false
    else
      return user_established_at > network_established_at ? true : false
    end
  end

end
