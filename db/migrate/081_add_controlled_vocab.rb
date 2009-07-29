# myExperiment: db/migrate/081_add_controlled_vocab.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddControlledVocab < ActiveRecord::Migration
  def self.up
    create_table :vocabularies do |t|
      t.column :user_id,          :integer
      t.column :title,            :string
      t.column :description,      :text
      t.column :description_html, :text
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end

    add_column :tags, :vocabulary_id,    :integer
    add_column :tags, :description,      :text
    add_column :tags, :description_html, :text
    add_column :tags, :created_at,       :datetime
    add_column :tags, :updated_at,       :datetime
  end

  def self.down
    drop_table :vocabularies

    remove_column :tags, :vocabulary_id
    remove_column :tags, :description
    remove_column :tags, :description_html
    remove_column :tags, :created_at
    remove_column :tags, :updated_at
  end
end
