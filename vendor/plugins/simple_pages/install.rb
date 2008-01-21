puts IO.read(File.join(File.dirname(__FILE__), 'README'))


unless File.exists?("#{RAILS_ROOT}/vendor/plugins/acts_as_versioned")
  puts "If you want to use version-control with your pages you'll need to run the following command to install Techno-Weenie's ActsAsVersioned plugin (highly recommended)"
  puts "    ruby #{RAILS_ROOT}/script/plugin install -x http://svn.techno-weenie.net/projects/plugins/acts_as_versioned"
  puts ''
end

unless File.exists?("#{RAILS_ROOT}/vendor/plugins/engines")
  puts "WARNING: you do not have the engines plugin installed.  This is a necessary requirement for the simple_pages plugin to work."
  puts "Please install the engines plugin by running the following command in your shell:"
  puts "    ruby #{RAILS_ROOT}/script/plugin install -x http://svn.rails-engines.org/engines/tags/rel_1.2.0/"
  puts ''
end

puts "To generate the migration for this plugin you'll need to run the following command:"
puts "    ruby script/generate plugin_migration"
puts ''
