class AddDoiToPacks < ActiveRecord::Migration
  def self.up
    add_column :packs, :doi, :string
  end

  def self.down
    remove_column :packs, :doi
  end
end
