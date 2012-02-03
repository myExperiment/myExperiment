class AddDeletionFlagsToMessages < ActiveRecord::Migration
  
  # this migration was required to implement "sent messages" feature;
  #
  # the problem with the original table is that if only that was used for
  # both normal use and viewing "messages that i've sent" is that when the recipient
  # deletes the message, it disappears from "sent messages" of the sender as well;
  #
  # one potential solution was to create a new table that would store only 'sent' messages,
  # however that is not space efficient; 
  #
  # instead - original messages table will be used with two added flags:
  # "deleted_by_recipient" and "deleted_by_sender" to help make correct use
  # of just one copy of the message; when both flags will be 'true', message
  # entry will be deleted from the DB 
  
  def self.up
    add_column :messages, :deleted_by_sender,    :boolean, :default => false
    add_column :messages, :deleted_by_recipient, :boolean, :default => false
  end

  def self.down
    remove_column :messages, :deleted_by_sender
    remove_column :messages, :deleted_by_recipient
  end
end
