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


class Channel < ActiveRecord::Base
  belongs_to :projects
  has_many :channel_topics
  has_and_belongs_to_many :users do
    def cleanup
      ActiveRecord::Base.connection.execute("DELETE FROM channels_users WHERE last_seen < DATE_SUB(\'#{ Time.now.strftime("%Y-%m-%d %H:%M:%S") }\', INTERVAL 1 MINUTE) OR last_seen IS NULL")
    end
  end
  
  has_many :channelmessages, :order => 'created_at asc' do
    def since(time)
      find(:all, :conditions => ['created_at >= ?', time])
    end
  end
  
  def latest_channelmessages(condition='Today')
    startfrom=get_first_channelmessage(condition)
    channelmessages.find(:all, :conditions => ["id >= ?", startfrom], :order => 'id DESC').reverse
  end
  
  def users_just_left
    User.find_by_sql(["SELECT u.* FROM users u, channels_users cu WHERE cu.last_seen < DATE_SUB(?, INTERVAL 1 MINUTE) AND cu.user_id = u.id AND cu.channel_id = ?", Time.now, self.id])
  end
  
  def get_first_channelmessage(condition)
    case condition
      when 'Last Topic Change'
        @channelmessage = Channelmessage.find(:first, :order => "id DESC", :conditions => ["channel_id = ? AND level = 'topicchange'", self.id])
        #return @channelmessage.id-1 if @channelmessage
      when 'Today'
        @channelmessage = Channelmessage.find(:first, :order => "id ASC", :conditions => ["channel_id = ? AND created_at > ?", self.id, Time.now.midnight.strftime("%Y-%m-%d %H:%M:%S")])
      when 'Last 24 Hours'
        @channelmessage = Channelmessage.find(:first, :order => "id ASC", :conditions => ["channel_id = ? AND created_at > DATE_SUB(?, INTERVAL 1 DAY)", self.id, Time.now.strftime("%Y-%m-%d %H:%M:%S")])
      when 'Last Week'
        @channelmessage = Channelmessage.find(:first, :order => "id ASC", :conditions => ["channel_id = ? AND created_at > DATE_SUB(?, INTERVAL 6 DAY)", self.id, Time.now.midnight.strftime("%Y-%m-%d %H:%M:%S")])
    end
    return @channelmessage.id if @channelmessage
    return '0'
  end
end
