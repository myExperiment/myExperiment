class Network < ActiveRecord::Base
  validates_presence_of :user_id
  
  validates_presence_of :title
  
  validates_uniqueness_of :unique
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  has_many :relationships
  
  has_and_belongs_to_many :relations_of_mine,
                          :class_name => "Network",
                          :join_table => :relationships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :relation_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  has_and_belongs_to_many :relations_with_me,
                          :class_name => "Network",
                          :join_table => :relationships,
                          :foreign_key => :relation_id,
                          :association_foreign_key => :network_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
                          
  def relations
    (relations_of_mine + relations_with_me).uniq
  end
                          
  has_many :memberships
  
  has_and_belongs_to_many :members,
                          :class_name => "User",
                          :join_table => :memberships,
                          :foreign_key => :user_id,
                          :association_foreign_key => :network_id,
                          :conditions => ["accepted_at < ?", Time.now],
                          :order => "accepted_at DESC"
end
