# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

desc 'Rebuild Solr index'
task "myexp:refresh:solr" do
  require File.dirname(__FILE__) + '/config/environment'
  Workflow.rebuild_solr_index
  Blob.rebuild_solr_index
  User.rebuild_solr_index
  Network.rebuild_solr_index
  Pack.rebuild_solr_index
end

