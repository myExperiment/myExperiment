# myExperiment: app/models/profile.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Profile < ActiveRecord::Base
  
  validates_email_veracity_of :email
  
  validates_associated :owner, :picture
  
  validates_presence_of :user_id
  
  validates_format_of :website, :with => /^http:\/\//, :message => "must begin with http://", :if => Proc.new { |profile| !profile.website.nil? and !profile.website.empty? }
  
  validates_each :picture_id do |record, attr, value|
    # picture_id = nil  => null avatar
    #              n    => Picture.find(n)
    unless value.nil? or value.to_i == 0
      begin
        p = Picture.find(value)
      
        record.errors.add attr, 'invalid image (not owned)' if p.user_id.to_i != record.user_id.to_i
      rescue ActiveRecord::RecordNotFound
        record.errors.add attr, "invalid image (doesn't exist)"
      end
    end
  end
  
  format_attribute :body
  
  belongs_to :owner,
             :class_name => "User",
             :foreign_key => :user_id
  
  belongs_to :picture
  
  def avatar?
    not (picture_id.nil? or picture_id.zero?)
  end
  
  def location
    if (location_city.nil? or location_city.empty?) and (location_country.nil? or location_country.empty?)
      return nil
    elsif (location_city.nil? or location_city.empty?) or (location_country.nil? or location_country.empty?)
      return location_city unless location_city.nil? or location_city.empty?
      return location_country unless location_country.nil? or location_country.empty?
    else
      return "#{location_city}, #{location_country}"
    end
  end
end
