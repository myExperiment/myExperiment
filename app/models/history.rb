class History < ActiveRecord::Base
  belongs_to :user
  
  acts_as_ferret :fields => { :action => {}, 
                              :controller => {}, 
                              :params_id => {}, 
                              :user_id => { :index => :untokenized } }
end
