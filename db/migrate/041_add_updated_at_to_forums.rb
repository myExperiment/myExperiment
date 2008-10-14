# myExperiment: db/migrate/041_add_updated_at_to_forums.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddUpdatedAtToForums < ActiveRecord::Migration

  def self.up
    add_column :forums, :updated_at, :datetime

    ActiveRecord::Base.record_timestamps = false

    begin
      Forum.find_all.each do |forum|
        forum.updated_at = forum.contribution.updated_at
        forum.save
      end
      rescue
    end

    Contribution.find_all.each do |c|
      if c.updated_at < c.contributable.updated_at
        c.updated_at = c.contributable.updated_at
        c.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
  end

  def self.down
    remove_column :forums, :updated_at
  end

end

