class DropSemanticAnnotations < ActiveRecord::Migration
  def self.up
    drop_table :semantic_annotations
  end

  def self.down
  end
end
