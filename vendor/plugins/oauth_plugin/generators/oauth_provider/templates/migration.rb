class CreateOauthTables < ActiveRecord::Migration
  def self.up
    create_table :client_applications do |t|
      t.column :name, :string
      t.column :url, :string
      t.column :support_url, :string
      t.column :callback_url, :string
      t.column :key, :string, :limit=>50
      t.column :secret, :string, :limit=>50
      t.column :user_id, :integer

      t.column :created_at,  :datetime
      t.column :updated_at,  :datetime
    end
    add_index :client_applications,:key,:unique

    create_table :oauth_tokens do |t|
      t.column :user_id, :integer
      t.column :type, :string, :limit=>20
      t.column :client_application_id, :integer
      t.column :token, :string, :limit=>50
      t.column :secret, :string, :limit=>50
      t.column :authorized_at, :timestamp
      t.column :invalidated_at, :timestamp
      
      t.column :created_at,  :datetime
      t.column :updated_at,  :datetime
    end

    add_index :oauth_tokens,:token,:unique

    create_table :oauth_nonces do |t|
      t.column :nonce, :string
      t.column :timestamp, :integer

      t.column :created_at,  :datetime
      t.column :updated_at,  :datetime
    end
    add_index :oauth_nonces,[:nonce,:timestamp],:unique

  end

  def self.down
    drop_table :client_applications
    drop_table :oauth_tokens
    drop_table :oauth_nonces
  end

end

