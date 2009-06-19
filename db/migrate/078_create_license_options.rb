class CreateLicenseOptions < ActiveRecord::Migration
  def self.up
    create_table :license_options do |t|
      t.column :user_id, :integer
      t.column :title, :string
      t.column :description, :text
      t.column :description_html, :text
      t.column :uri, :string
      t.column :predicate, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    u = User.find_by_username(Conf.admins.first)
    if (u.blank?)
        uid = 1
    else
        uid = u.id
    end

    LicenseOption.create(:user_id => uid, :title => 'Permits Reproduction', :description => 'Permits making multiple copies', :uri => 'http://creativecommons.org/ns#Reproduction', :predicate => 'permits')
    LicenseOption.create(:user_id => uid, :title => 'Permits Distribution', :description => 'Permits distribution, public display, and publicly performance', :uri => 'http://creativecommons.org/ns#Distribution', :predicate => 'permits')
    LicenseOption.create(:user_id => uid, :title => 'Permits Derivative Works', :description => 'Permits distribution of derivative works', :uri => 'http://creativecommons.org/ns#DerivativeWorks', :predicate => 'permits')
    LicenseOption.create(:user_id => uid, :title => 'Permits High Income Nation Use', :description => 'Permits use in a non-developing country', :uri => 'http://creativecommons.org/ns#HighIncomeNationUse', :predicate => 'permits')
    LicenseOption.create(:user_id => uid, :title => 'Permits Sharing', :description => 'Permits commercial derivatives, but only non-commercial distribution', :uri => 'http://creativecommons.org/ns#Sharing', :predicate => 'permits')
    LicenseOption.create(:user_id => uid, :title => 'Requires Notice', :description => 'Requries copyright and license notices be kept intact', :uri => 'http://creativecommons.org/ns#Notice', :predicate => 'requires')
    LicenseOption.create(:user_id => uid, :title => 'Requires Attribution', :description => 'Requires credit be given to copyright holder and/or author', :uri => 'http://creativecommons.org/ns#Attribution', :predicate => 'requires')
    LicenseOption.create(:user_id => uid, :title => 'Requires Share Alike', :description => 'Requires derivative works be licensed under the same terms or compatible terms as the original work', :uri => 'http://creativecommons.org/ns#ShareAlike', :predicate => 'requires')
    LicenseOption.create(:user_id => uid, :title => 'Requires Source Code', :description => 'Requires source code (the preferred form for making modifications) must be provided when exercising some rights granted by the license.', :uri => 'http://creativecommons.org/ns#SourceCode', :predicate => 'requires')
    LicenseOption.create(:user_id => uid, :title => 'Requires Copyleft', :description => 'Requires derivative and combined works must be licensed under specified terms, similar to those on the original work', :uri => 'http://creativecommons.org/ns#Copyleft', :predicate => 'requires')
    LicenseOption.create(:user_id => uid, :title => 'Requires Lesser Copyleft', :description => 'Requires derivative works must be licensed under specified terms, with at least the same conditions as the original work; combinations with the work may be licensed under different terms', :uri => 'http://creativecommons.org/ns#LesserCopyleft', :predicate => 'requires')
    LicenseOption.create(:user_id => uid, :title => 'Prohibits Commercial User', :description => 'Prohibits exercising rights for commercial purposes', :uri => 'http://creativecommons.org/ns#CommercialUse', :predicate => 'prohibits')
  end

  def self.down
    drop_table :license_options
  end
end
