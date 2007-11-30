# myExperiment: app/models/blog.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'

class Blog < ActiveRecord::Base
  acts_as_contributable
  
  has_many :posts,
           :class_name => "BlogPost",
           :order => "blog_posts.created_at DESC",
           :dependent => :destroy
           
  validates_presence_of :title
end
