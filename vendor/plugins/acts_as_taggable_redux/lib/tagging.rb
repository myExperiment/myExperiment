class Tagging < ActiveRecord::Base

  belongs_to :tag, :counter_cache => true
  belongs_to :taggable, :polymorphic => true
  belongs_to :user

  validates_presence_of :tag
  validates_presence_of :user
  validates_presence_of :taggable

  def before_validation
    if taggable
      return false unless taggable.respond_to?('add_tag')
    end
  end

  # returns the 'last created' Taggings
  # the maximum number of results is set by #limit#
  def self.latest(limit=10)
    self.find(:all,
              :order => "created_at DESC",
              :limit => limit)
  end

  def label
    return tag.name if tag
  end

  def label=(label)
    self.tag = Tag.find_by_name(label)    if self.tag.nil?
    self.tag = Tag.create(:name => label) if self.tag.nil?
  end
end

