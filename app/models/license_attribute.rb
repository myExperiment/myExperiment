class LicenseAttribute < ActiveRecord::Base

  attr_accessible :license, :license_option

  belongs_to :license
  belongs_to :license_option

  validates_presence_of :license_option_id, :license_id
end
