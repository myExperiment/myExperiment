class Network < ActiveRecord::Base
  validates_presence_of :user_id
  
  validates_presence_of :title
  
  validates_uniqueness_of :unique
  
  has_many :relationships
  
  has_and_belongs_to_many :relations,
                          :class_name => "Network",
                          :join_table => :relationships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :relation_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  has_many :memberships
  
  has_and_belongs_to_many :users,
                          :join_table => :memberships,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
end
