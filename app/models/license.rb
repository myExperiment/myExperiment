class License < ActiveRecord::Base
  format_attribute :description

  belongs_to :user

  validates_presence_of :user_id, :title, :url
  validates_uniqueness_of :title, :url
  
  has_many :license_attributes, 
           :dependent => :destroy
           
   #def self.packs_with_contributable(contributable)
   def self.find_license_options_set(license)
     if license.id
      license_id=license.id
     else
      license_id='0'
     end
     return LicenseOption.find_by_sql("SELECT license_options.title, license_options.description, license_options.id, lic_att.isset FROM license_options LEFT JOIN ( SELECT license_option_id, 1 AS isset FROM license_attributes WHERE license_id = #{license_id}) AS lic_att ON license_options.id = lic_att.license_option_id")
  end
  def license_attributes
     return LicenseAttribute.find_by_sql("SELECT * FROM license_attributes INNER JOIN license_options on license_attributes.license_option_id=license_options.id WHERE license_id = #{self.id}")
  end
  
end
