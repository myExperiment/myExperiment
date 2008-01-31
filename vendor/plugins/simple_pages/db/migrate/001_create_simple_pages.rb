class CreateSimplePages < ActiveRecord::Migration
  def self.up
    create_table :simple_pages do |t|
      t.column  :filename,      :string
      t.column  :title,         :string
      t.column  :content,       :text
      t.column  :created_at,    :datetime
      t.column  :updated_at,    :datetime
    end
    SimplePage.create_versioned_table if SimplePage.respond_to?(:create_versioned_table)
  end

  def self.down
    drop_table :simple_pages
    SimplePage.drop_versioned_table if SimplePage.respond_to?(:drop_versioned_table)
  end
end
