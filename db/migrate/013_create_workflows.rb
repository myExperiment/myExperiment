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

class CreateWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :scufl, :binary
      t.column :image, :string
      
      t.column :title, :string
      t.column :unique, :string
      t.column :description, :text
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      
      t.column :license, :string, 
               :limit => 10, :null => false, 
               :default => "a"
    end
    
    Workflow.create_versioned_table
  end

  def self.down
    drop_table :workflows
    
    Workflow.drop_versioned_table
  end
end
