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

desc 'Refresh workflow metadata'
task "myexp:refresh:workflows" do
  require File.dirname(__FILE__) + '/config/environment'

  conn = ActiveRecord::Base.connection

  conn.execute('TRUNCATE workflow_processors')

  Workflow.find(:all).each do |w|
    w.extract_metadata
  end
end

desc 'Import data from BioCatalogue'
task "myexp:import:biocat" do
  require File.dirname(__FILE__) + '/config/environment'

  Contribution.delete_all("contributable_type = 'Service'")

  conn = ActiveRecord::Base.connection

  conn.execute('TRUNCATE service_categories')
  conn.execute('TRUNCATE service_deployments')
  conn.execute('TRUNCATE service_providers')
  conn.execute('TRUNCATE service_tags')
  conn.execute('TRUNCATE service_types')
  conn.execute('TRUNCATE services')

  BioCatalogueImport.import_biocatalogue
end

