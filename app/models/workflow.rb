require 'acts_as_contributable'

class Workflow < ActiveRecord::Base
  acts_as_contributable
  
  acts_as_versioned
  
  acts_as_ferret :fields => { :title => { :store => :yes }, 
                              :description => { :store => :yes }, 
                              :tag_list => { :store => :yes },
                              :rating => { :index => :untokenized } }
  
  validates_presence_of :title, :scufl
  
  validates_uniqueness_of :unique

  file_column :image, :magick => {
    :versions => {
      :thumb    => { :size => "100x100!" }, 
      :medium   => { :size => "650x300>" },
      :padlock  => { :size => "100x100!",
                     :overlay   => { :file => "#{RAILS_ROOT}/public/images/padlock.gif", 
                                     :alignment => :bottom_left,
                                     :offset => 3 } }
    }
  }
  
  non_versioned_fields.push "image" # acts_as_versioned and file_column don't get on
end
