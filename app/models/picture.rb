# myExperiment: app/models/picture.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

#class Picture < ActiveRecord::Base
class Picture < FlexImage::Model
  validates_associated :owner
  
  validates_presence_of :user_id, :data
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
             
  has_many :profiles,
           :foreign_key => :picture_id,
           :dependent => :nullify
           
  has_many :picture_selections,
           :dependent => :destroy
           
  def select!
    unless selected?
      owner.profile.update_attribute :picture_id, id
      return true
    else
      return false
    end
  end
  
  def selected?
    owner.profile.avatar? and owner.profile.picture.id.to_i == id.to_i
  end
  
  #file_column :data, :magick => {
  #  :versions => {
  #    :small    => { :size => "50x50!" }, 
  #    :medium   => { :size => "100x100!" },
  #    :large => { :size => "200x200!" }
  #  }
  #}
end
