require 'acts_as_contributable'

class Workflow < ActiveRecord::Base
  acts_as_contributable
  
  acts_as_versioned

  file_column :image, :magick => {
    :versions => {
      :thumb =>  {:size => "100x100!"}, 
      :medium => {:size =>"650x300>" }
    }#, :image_required => false
  }
end
