class CreateSemanticAnnotations < ActiveRecord::Migration
  def self.up
    create_table :semantic_annotations do |t|
      t.integer :subject_id
      t.string :subject_type
      t.string :predicate
      t.string :object
    end
  end

  def self.down
    drop_table :semantic_annotations
  end
end
