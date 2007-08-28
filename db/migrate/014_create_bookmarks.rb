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

class CreateBookmarks < ActiveRecord::Migration
  def self.up
    create_table "bookmarks", :force => true do |t|
      t.column "title", :string, :limit => 50, :default => ""
      t.column "created_at", :datetime, :null => false
      t.column "bookmarkable_type", :string, :limit => 15, :default => "", :null => false
      t.column "bookmarkable_id", :integer, :default => 0, :null => false
      t.column "user_id", :integer, :default => 0, :null => false
    end
  
    add_index "bookmarks", ["user_id"], :name => "fk_bookmarks_user"
  end

  def self.down
    drop_table :bookmarks
  end
end
