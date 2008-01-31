class Tagging < ActiveRecord::Base
  belongs_to :tag, :counter_cache => true
  belongs_to :taggable, :polymorphic => true
  belongs_to :user
  
  # returns the 'last created' Taggings
  # the maximum number of results is set by #limit#
  def self.latest(limit=10)
    self.find(:all,
              :order => "created_at DESC",
              :limit => limit)
  end
end