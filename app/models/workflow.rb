require 'acts_as_contributable'

class Workflow < ActiveRecord::Base
  acts_as_contributable
  
  acts_as_versioned
  
  validates_presence_of :title, :scufl
  
  validates_uniqueness_of :unique

  file_column :image, :magick => {
    :versions => {
      :thumb =>  {:size => "100x100!"}, 
      :medium => {:size =>"650x300>" }
    }
  }
end
