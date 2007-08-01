class Message < ActiveRecord::Base
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
end
