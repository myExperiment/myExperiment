class Relationship < ActiveRecord::Base
  belongs_to :network
  
  belongs_to :network,
             :as => :relation,
             :foreign_key => :relation_id
end
