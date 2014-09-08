class LicenseOption < ActiveRecord::Base

  attr_accessible :user_id, :title, :description, :uri, :predicate

  format_attribute :description

  belongs_to :user

  validates_presence_of :user_id, :title, :uri, :predicate
  validates_uniqueness_of :title, :uri
end
