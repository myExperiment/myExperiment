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

class Message < ActiveRecord::Base
  validates_associated :u_from, :u_to
  
  validates_presence_of :to, :from
  
  validates_length_of :subject, :maximum => 80
  
  belongs_to :u_from,
             :class_name => "User",
             :foreign_key => :from
             
  belongs_to :u_to,
             :class_name => "User",
             :foreign_key => :to
             
  belongs_to :reply_to,
             :class_name => "Message",
             :foreign_key => :reply_id
             
  has_many :replies,
           :class_name => "Message",
           :foreign_key => :reply_id,
           :order => "created_at DESC"
             
  def read!
    update_attribute :read_at, Time.now
  end
  
  def read?
    self.read_at != nil
  end
  
  def reply?
    self.reply_id != nil
  end
end
