# myExperiment: app/models/message.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Message < ActiveRecord::Base
  validates_associated :u_from, :u_to
  
  validates_presence_of :to, :from
  
  validates_length_of :subject, :maximum => 80
  
  belongs_to :u_from,
             :class_name => "User",
             :foreign_key => :from
             
  belongs_to :u_to,
             :class_name => "User",
             :foreign_key => :to
             
  belongs_to :reply_to,
             :class_name => "Message",
             :foreign_key => :reply_id
             
  has_many :replies,
           :class_name => "Message",
           :foreign_key => :reply_id,
           :order => "created_at DESC"
             
  def read!
    update_attribute :read_at, Time.now if (self.read_at == nil)
  end
  
  def read?
    self.read_at != nil
  end
  
  def reply?
    self.reply_id != nil
  end
  
  # returns 'true' when user with 'user_id' is the recipient of the message
  def recipient?(user_id)
    return (self.to.to_i == user_id.to_i)
  end
  
  
  # 'messages' table has two flags - "deleted_by_recipient" & "deleted_by_sender" -
  # when a user 'deletes' a message, a relevant flag is marked with "true" instead;
  # when both flags will be "true", the message DB entry is automatically destroyed
  # 
  # INPUT: (deleted_by_recipient == 1)  => deleted by the recipient;
  #        (deleted_by_recipient == 0) => deleted by sender;
  #
  # RETURN VALUE: "true" if both delete flags on message's record are set to "true",
  # and so the message needs to be destroyed; "false" if message's record should remain in DB
  def mark_as_deleted!(deleted_by_recipient)
    
    # first of all, mark the message as deleted by current_user -> sender or recipient
    if deleted_by_recipient
      self.deleted_by_recipient = true
    else
      self.deleted_by_sender = true
    end
    self.save
    
    # now check if both deletion flags are true
    return (self.deleted_by_recipient == true && self.deleted_by_sender == true)
  end
  
  format_attribute :body
end
