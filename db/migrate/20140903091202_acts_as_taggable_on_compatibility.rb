class ActsAsTaggableOnCompatibility < ActiveRecord::Migration

  def change
    rename_column :taggings, :user_id, :tagger_id
    add_column :taggings, :tagger_type, :string, :default => 'User'
    add_column :taggings, :context, :string, :limit => 128, :default => 'tags'
  end

end
