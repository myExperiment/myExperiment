class Network < ActiveRecord::Base
  has_many :relationships
  
  has_and_belongs_to_many :networks,
                          :as => :relations,
                          :join_table => :relationships,
                          :foreign_key => :network_id,
                          :association_foreign_key => :relation_id
                          
  has_many :memberships
  
  has_and_belongs_to_many :users,
                          :join_table => :memberships
end
