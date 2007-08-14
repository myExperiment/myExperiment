class Moderatorship < ActiveRecord::Base
  belongs_to :forum
  belongs_to :user
  before_create { |r| count(:all, :conditions => ['forum_id = ? and user_id = ?', r.forum_id, r.user_id]).zero? }
  
  validates_each :user_id do |model, attr, value|
    model.errors.add attr, "owner is automatically a moderator of this forum" if ((c = model.forum.contribution.contributor).type.to_s == "User" and c.id.to_i == value.to_i) or (c.type.to_s == "Network" and c.user_id.to_i == value.to_i)
    model.errors.add attr, "already a moderator of this forum" if self.find(:first, :conditions => ["forum_id = ? AND user_id = ?", model.forum.id, value])
  end
end
