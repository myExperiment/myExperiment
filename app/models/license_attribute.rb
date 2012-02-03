class LicenseAttribute < ActiveRecord::Base
  belongs_to :license
  belongs_to :license_option

  validates_presence_of :license_option_id, :license_id
end
