class AddUserAgentToViewingsAndDownloads < ActiveRecord::Migration
  
  # user-agent will now be stored with "viewing" and "download" entries,
  # where initial check showed that the current user-agent is not a bot
  #
  # for viewings/downloads made by bots, no entries in viewings/downloads
  # tables are created
  
  def self.up
    add_column :viewings, :user_agent, :string, :default => nil
#   add_column :downloads, :user_agent, :string, :default => nil
  end

  def self.down
    remove_column :viewings, :user_agent
#   remove_column :downloads, :user_agent
  end
end
