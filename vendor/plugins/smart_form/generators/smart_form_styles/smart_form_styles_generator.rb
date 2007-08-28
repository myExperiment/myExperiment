class SmartFormStylesGenerator < Rails::Generator::Base
  def manifest
    STDOUT.sync=true
    record do |m|
      m.directory File.join('public', 'stylesheets')
      m.template "smart_form.css", File.join('public', 'stylesheets','smart_form.css')
      print <<-"EOF"
Sweeeet...
The sylet-sheet "smart_form.css" has been created in your public/stylesheets folder.
Don't forget to add the following line to the head section of your layout:
        
<%= stylesheet_link_tag "smart_form" %>

Thank you, and enjoy!
-Jabberwock
      
      EOF
    end
  end
end
