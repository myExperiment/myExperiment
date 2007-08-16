require 'acts_as_contributable'

class Blog < ActiveRecord::Base
  acts_as_contributable
  
  has_many :posts,
           :class_name => "BlogPost",
           :order => "blog_posts.created_at DESC"
           
  validates_presence_of :title
end
