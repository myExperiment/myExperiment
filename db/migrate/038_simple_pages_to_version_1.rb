class SimplePagesToVersion1 < ActiveRecord::Migration
  def self.up
    Rails.plugins["simple_pages"].migrate(1)
  end

  def self.down
    Rails.plugins["simple_pages"].migrate(0)
  end
end
