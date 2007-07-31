class Message < ActiveRecord::Base
  validates_presence_of :from, :to
  
  validates_length_of :subject, :maximum => 80
  
  belongs_to :from,
             :class_name => "User",
             :foreign_key => :from
             
  belongs_to :to,
             :class_name => "User",
             :foreign_key => :to
             
  belongs_to :reply,
             :class_name => "Message",
             :foreign_key => :reply_id
             
  def mark_as_read
    begin
      self.read_at ||= Time.now
      self.save!
    rescue RecordNotSaved
      nil
    end
  end
end
