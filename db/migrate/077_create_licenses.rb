class CreateLicenses < ActiveRecord::Migration
  def self.up
    create_table :licenses do |t|
      t.column :user_id, :integer
      t.column :unique_name, :string
      t.column :title, :string
      t.column :description, :text
      t.column :description_html, :text
      t.column :url, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    u = User.find_by_username(Conf.admins.first)
    if (u.blank?)
        uid = 1
    else
        uid=u.id
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
 end
 
 def self.down
    drop_table :licenses
  end
end
