class BlogPost < ActiveRecord::Base
  belongs_to :blog
  
  validates_presence_of :title, :body
end
