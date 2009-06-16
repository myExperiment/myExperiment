class CreateLicenseAttributes < ActiveRecord::Migration
  def self.up
    create_table :license_attributes do |t|
      t.column :license_id, :integer
      t.column :license_option_id, :integer
      t.column :created_at, :datetime
    end
    reproduction = LicenseOption.find(:first,:conditions=>['title = ?','Permits Reproduction'])
    distribution = LicenseOption.find(:first,:conditions=>['title = ?','Permits Distribution'])
    derivs = LicenseOption.find(:first,:conditions=>['title = ?','Permits Derivative Works'])
    notice = LicenseOption.find(:first,:conditions=>['title = ?','Requires Notice'])
    attribution = LicenseOption.find(:first,:conditions=>['title = ?','Requires Attribution'])
    sharealike = LicenseOption.find(:first,:conditions=>['title = ?','Requires Share Alike'])
    sourcecode = LicenseOption.find(:first,:conditions=>['title = ?','Requires Source Code'])
    commercial = LicenseOption.find(:first,:conditions=>['title = ?','Prohibits Commercial Use'])
    
    #by-nd
    lic = License.find(:first,:conditions=>['unique_name = ?','by-nd'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => attribution )
    lic.save
    
    #by-sa
    lic = License.find(:first,:conditions=>['unique_name = ?','by-sa'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => attribution )
    LicenseAttribute.create(:license => lic, :license_option => derivs )
    LicenseAttribute.create(:license => lic, :license_option => sharealike )
    lic.save
    
    #by
    lic = License.find(:first,:conditions=>['unique_name = ?','by'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => attribution )
    LicenseAttribute.create(:license => lic, :license_option => derivs )
    lic.save
    
    #by-nc-nd
    lic = License.find(:first,:conditions=>['unique_name = ?','by-nc-nd'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => attribution )
    LicenseAttribute.create(:license => lic, :license_option => commercial )
    lic.save
    
    #by-nc
    lic = License.find(:first,:conditions=>['unique_name = ?','by-nc'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => attribution )
    LicenseAttribute.create(:license => lic, :license_option => commercial )
    LicenseAttribute.create(:license => lic, :license_option => derivs )
    lic.save
    
    #by-nc-sa
    lic = License.find(:first,:conditions=>['unique_name = ?','by-nc-sa'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => attribution )
    LicenseAttribute.create(:license => lic, :license_option => commercial )
    LicenseAttribute.create(:license => lic, :license_option => derivs )
    LicenseAttribute.create(:license => lic, :license_option => sharealike )
    lic.save
    
    #MIT
    lic = License.find(:first,:conditions=>['unique_name = ?','MIT'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => sourcecode )
    LicenseAttribute.create(:license => lic, :license_option => derivs )
    lic.save
    
    #BSD
    lic = License.find(:first,:conditions=>['unique_name = ?','BSD'])
    LicenseAttribute.create(:license => lic, :license_option => reproduction )
    LicenseAttribute.create(:license => lic, :license_option => distribution )
    LicenseAttribute.create(:license => lic, :license_option => notice )
    LicenseAttribute.create(:license => lic, :license_option => sourcecode )
    LicenseAttribute.create(:license => lic, :license_option => derivs )
    lic.save
    
  end

  def self.down
    drop_table :license_attributes
  end
end
