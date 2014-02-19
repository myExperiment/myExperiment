# Create licenses
u = User.find_by_username(Conf.admins.first)
if (u.blank?)
  uid = 1
else
  uid = u.id
end

#by-nd
License.create(:user_id => uid, :unique_name => 'by-nd', :title => 'Creative Commons Attribution-No Derivative Works 3.0 Unported License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
</ul>
<h4>Under the following conditions:</h4>
<ul>
  <li>Attribution &mdash; You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).</li>
  <li>No Derivative Works &mdash; You may not alter, transform, or build upon this work.</li>
</ul>
<h4>With the understanding that:</h4>
<ul>
  <li>Waiver &mdash; Any of the above conditions can be waived if you get permission from the copyright holder.</li>
  <li>Other Rights &mdash; In no way are any of the following rights affected by the license:
    <ul>
      <li>Your fair dealing or fair use rights;</li>
      <li>The author's moral rights;</li>
      <li>Rights other persons may have either in the work itself or in how the work is used, such as publicity or privacy rights.</li>
    </ul>
  </li>
  <li>Notice &mdash; For any reuse or distribution, you must make clear to others the license terms of this work. The best way to do this is with a link to <a href='http://creativecommons.org/licenses/by-nd/3.0/'>http://creativecommons.org/licenses/by-nd/3.0/</a>.</li>
</ul>", :url => 'http://creativecommons.org/licenses/by-nd/3.0/')

#by-sa
License.create(:user_id => uid, :unique_name => 'by-sa', :title => 'Creative Commons Attribution-Share Alike 3.0 Unported License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
  <li>to Remix &mdash; to adapt the work</li>
</ul>
<h4>Under the following conditions:</h4>
<ul>
  <li>Attribution &mdash; You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).</li>
  <li>Share Alike &mdash; If you alter, transform, or build upon this work, you may distribute the resulting work only under the same, similar or a compatible license.</li>
</ul>

<h4>With the understanding that:</h4>
<ul>
  <li>Waiver &mdash; Any of the above conditions can be waived if you get permission from the copyright holder.</li>
  <li>Other Rights &mdash; In no way are any of the following rights affected by the license:
    <ul>
      <li>Your fair dealing or fair use rights;</li>
      <li>The author's moral rights;</li>
      <li>Rights other persons may have either in the work itself or in how the work is used, such as publicity or privacy rights.</li>
    </ul>
  </li>
  <li>Notice &mdash; For any reuse or distribution, you must make clear to others the license terms of this work. The best way to do this is with a link to <a href='http://creativecommons.org/licenses/by-sa/3.0/'>http://creativecommons.org/licenses/by-sa/3.0/</a>.</li>
</ul>", :url => 'http://creativecommons.org/licenses/by-sa/3.0/')

#by
License.create(:user_id => uid, :unique_name => 'by', :title => 'Creative Commons Attribution 3.0 Unported License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
  <li>to Remix &mdash; to adapt the work</li>
</ul>
<h4>Under the following conditions:</h4>
<ul>
  <li>Attribution &mdash; You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).</li>
</ul>
<h4>With the understanding that:</h4>
<ul>
  <li>Waiver &mdash; Any of the above conditions can be waived if you get permission from the copyright holder.</li>
  <li>Other Rights &mdash; In no way are any of the following rights affected by the license:
    <ul>
      <li>Your fair dealing or fair use rights;</li>
      <li>The author's moral rights;</li>
      <li>Rights other persons may have either in the work itself or in how the work is used, such as publicity or privacy rights.</li>
    </ul>
  </li>
  <li>Notice &mdash; For any reuse or distribution, you must make clear to others the license terms of this work. The best way to do this is with a link to <a href='http://creativecommons.org/licenses/by/3.0/'>http://creativecommons.org/licenses/by/3.0/</a>.</li>
</ul>", :url => 'http://creativecommons.org/licenses/by/3.0/')


#by-nc-nd
License.create(:user_id => uid, :unique_name => 'by-nc-nd', :title => 'Creative Commons Attribution-Noncommercial-No Derivative Works 3.0 Unported License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
</ul>
<h4>Under the following conditions:</h4>
<ul>
  <li>Attribution &mdash; You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).</li>
  <li>Noncommercial &mdash; You may not use this work for commercial purposes.</li>
  <li>No Derivative Works &mdash; You may not alter, transform, or build upon this work.</li>
</ul>
<h4>With the understanding that:</h4>
<ul>
  <li>Waiver &mdash; Any of the above conditions can be waived if you get permission from the copyright holder.</li>
  <li>Other Rights &mdash; In no way are any of the following rights affected by the license:
    <ul>
      <li>Your fair dealing or fair use rights;</li>
      <li>The author's moral rights;</li>
      <li>Rights other persons may have either in the work itself or in how the work is used, such as publicity or privacy rights.</li>
    </ul>
  </li>
  <li>Notice &mdash; For any reuse or distribution, you must make clear to others the license terms of this work. The best way to do this is with a link to <a href='http://creativecommons.org/licenses/by-nc-nd/3.0/'>http://creativecommons.org/licenses/by-nc-nd/3.0/</a>.</li>
</ul>", :url => 'http://creativecommons.org/licenses/by-nc-nd/3.0/')

#by-nc
License.create(:user_id => uid, :unique_name => 'by-nc', :title => 'Creative Commons Attribution-Noncommercial 3.0 Unported License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
  <li>to Remix &mdash; to adapt the work</li>
</ul>
<h4>Under the following conditions:</h4>
<ul>
  <li>Attribution &mdash; You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).</li>
  <li>Noncommercial &mdash; You may not use this work for commercial purposes.</li>
</ul>
<h4>With the understanding that:</h4>
<ul>
  <li>Waiver &mdash; Any of the above conditions can be waived if you get permission from the copyright holder.</li>
  <li>Other Rights &mdash; In no way are any of the following rights affected by the license:
    <ul>
      <li>Your fair dealing or fair use rights;</li>
      <li>The author's moral rights;</li>
      <li>Rights other persons may have either in the work itself or in how the work is used, such as publicity or privacy rights.</li>
    </ul>
  </li>
  <li>Notice &mdash; For any reuse or distribution, you must make clear to others the license terms of this work. The best way to do this is with a link to <a href='http://creativecommons.org/licenses/by-nc/3.0/'>http://creativecommons.org/licenses/by-nc/3.0/</a>.</li>
</ul>", :url => 'http://creativecommons.org/licenses/by-nc/3.0/')

#by-nc-sa
License.create(:user_id => uid, :unique_name => 'by-nc-sa', :title => 'Creative Commons Attribution-Noncommercial-Share Alike 3.0 Unported License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
  <li>to Remix &mdash; to adapt the work</li>
</ul>  
<h4>Under the following conditions:</h4>
<ul>
  <li>Attribution &mdash; You must attribute the work in the manner specified by the author or licensor (but not in any way that suggests that they endorse you or your use of the work).</li>
  <li>Noncommercial &mdash; You may not use this work for commercial purposes.</li>
  <li>Share Alike &mdash; If you alter, transform, or build upon this work, you may distribute the resulting work only under the same or similar license to this one.</li>
</ul>
<h4>With the understanding that:</h4>
<ul>
  <li>Waiver &mdash; Any of the above conditions can be waived if you get permission from the copyright holder.</li>
  <li>Other Rights &mdash; In no way are any of the following rights affected by the license:
    <ul>
      <li>Your fair dealing or fair use rights;</li>
      <li>The author's moral rights;</li>
      <li>Rights other persons may have either in the work itself or in how the work is used, such as publicity or privacy rights.</li>
    </ul>
  </li>
  <li>Notice &mdash; For any reuse or distribution, you must make clear to others the license terms of this work. The best way to do this is with a link to <a href='http://creativecommons.org/licenses/by-nc-sa/3.0/'>http://creativecommons.org/licenses/by-nc-sa/3.0/</a>.</li>
</ul>", :url => 'http://creativecommons.org/licenses/by-nc-sa/3.0/')

#MIT
License.create(:user_id => uid, :unique_name => 'MIT', :title => 'MIT License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
  <li>to Remix &mdash; to adapt the work</li>
</ul>
<h4>Under the following conditions:</h4>
<ul>
  <li>The copyright notice and license shall be included in all copies or substantial portions of the software.</li>
  <li>Any of the above conditions can be waived if you get permission from the copyright holder.</li>
</ul>", :url => 'http://creativecommons.org/licenses/MIT/')

#BSD
License.create(:user_id => uid, :unique_name => 'BSD', :title => 'BSD License', :description => "<h4>You are free:</h4>
<ul>
  <li>to Share &mdash; to copy, distribute and transmit the work</li>
  <li>to Remix &mdash; to adapt the work</li>
</ul>
<h4>Under the following conditions:</h4>
<ul>
  <li>No Endorsement. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission.</li>
  <li>You must retain the license terms and copyright notice in any source code distribution and reproduce them in documentation for binary distributions.</li>
  <li>Any of the above conditions can be waived if you get permission from the copyright holder.</li>
</ul>", :url => 'http://creativecommons.org/licenses/BSD/')

#GPL
License.create(:user_id => uid, :unique_name => 'GPL', :title => 'GNU General Public License (GPL) 2.0', :description => "<p>The GNU General Public License is a Free Software license. Like any Free Software license, it grants to you the four following freedoms:</p>
<ol>
  <li>The freedom to run the program for any purpose.</li>
  <li>The freedom to study how the program works and adapt it to your needs.</li>
  <li>The freedom to redistribute copies so you can help your neighbor.</li>
  <li>The freedom to improve the program and release your improvements to the public, so that the whole community benefits.</li>
</ol>
<p>You may exercise the freedoms specified here provided that you comply with the express conditions of this license. The principal conditions are:</p>
<ul>
  <li>You must conspicuously and appropriately publish on each copy distributed an appropriate copyright notice and disclaimer of warranty and keep intact all the notices that refer to this License and to the absence of any warranty; and give any other recipients of the Program a copy of the GNU General Public License along with the Program. Any translation of the GNU General Public License must be accompanied by the GNU General Public License.</li>
  <li>If you modify your copy or copies of the program or any portion of it, or develop a program based upon it, you may distribute the resulting work provided you do so under the GNU General Public License. Any translation of the GNU General Public License must be accompanied by the GNU General Public License.</li>
  <li>If you copy or distribute the program, you must accompany it with the complete corresponding machine-readable source code or with a written offer, valid for at least three years, to furnish the complete corresponding machine-readable source code.</li>
</ul>
<p>Any of the above conditions can be waived if you get permission from the copyright holder.</p>", :url => 'http://creativecommons.org/licenses/GPL/2.0/')

#LGPL
License.create(:user_id => uid, :unique_name => 'LGPL', :title => 'GNU Lesser General Public License (LGPL) 2.1', :description => "<p>The GNU Lesser General Public License is a Free Software license. Like any Free Software license, it grants to you the four following freedoms:</p>
<ol>
  <li>The freedom to run the program for any purpose.</li>
  <li>The freedom to study how the program works and adapt it to your needs.</li>
  <li>The freedom to redistribute copies so you can help your neighbor.</li>
  <li>The freedom to improve the program and release your improvements to the public, so that the whole community benefits.</li>
</ol>
<p>You may exercise the freedoms specified here provided that you comply with the express conditions of this license. The LGPL is intended for software libraries, rather than executable programs. The principal conditions are:<p>
<ul>
  <li>You must conspicuously and appropriately publish on each copy distributed an appropriate copyright notice and disclaimer of warranty and keep intact all the notices that refer to this License and to the absence of any warranty; and give any other recipients of the Program a copy of the GNU Lesser General Public License along with the Program. Any translation of the GNU Lesser General Public License must be accompanied by the GNU Lesser General Public License.</li>
  <li>If you modify your copy or copies of the library or any portion of it, you may distribute the resulting library provided you do so under the GNU Lesser General Public License. However, programs that link to the library may be licensed under terms of your choice, so long as the library itself can be changed. Any translation of the GNU Lesser General Public License must be accompanied by the GNU Lesser General Public License.</li>
  <li>If you copy or distribute the program, you must accompany it with the complete corresponding machine-readable source code or with a written offer, valid for at least three years, to furnish the complete corresponding machine-readable source code.</li>
</ul>
<p>Any of the above conditions can be waived if you get permission from the copyright holder.</p>", :url => 'http://creativecommons.org/licenses/LGPL/2.1/')

#Apache
License.create(:user_id => uid, :unique_name => 'Apache', :title => 'Apache License v2.0', :description => "<p>See <a href='http://www.apache.org/licenses/LICENSE-2.0'>http://www.apache.org/licenses/LICENSE-2.0</a></p>", :url => "http://www.apache.org/licenses/LICENSE-2.0")

#Public Domain
License.create(:user_id => uid, :unique_name => 'CC0', :title => 'CC0 1.0 Universal (Public Domain License)', :description => "<p>The person who associated a work with this document has dedicated this work to the Commons by waiving all of his or her rights to the work under copyright law and all related or neighboring legal rights he or she had in the work, to the extent allowable by law.</p>
<p><b>Other Rights</b> &mdash; In no way are any of the following rights affected by CC0:</p>
<ul>
  <li>Patent or trademark rights held by the person who associated this document with a work.</li>
  <li>Rights other persons may have either in the work itself or in how the work is used, such as publicity or privacy rights.</li>
</ul>", :url => "http://creativecommons.org/publicdomain/zero/1.0/")



# License Options
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
LicenseOption.create(:user_id => uid, :title => 'Prohibits Commercial Use', :description => 'Prohibits exercising rights for commercial purposes', :uri => 'http://creativecommons.org/ns#CommercialUse', :predicate => 'prohibits')

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
