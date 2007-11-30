# myExperiment: app/models/blog_post.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlogPost < ActiveRecord::Base
  belongs_to :blog
  
  format_attribute :body

  validates_presence_of :title, :body
end
