class Viewing < ActiveRecord::Base
  belongs_to :contribution,
             :counter_cache => true
             
  belongs_to :user,
             :counter_cache => true
             
  validates_presence_of :contribution
end
