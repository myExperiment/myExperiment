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
    update_attribute :read_at, Time.now
  end
  
  def read?
    self.read_at != nil
  end
  
  def reply?
    self.reply_id != nil
  end
  
  format_attribute :body
end
