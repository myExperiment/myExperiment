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
  Service.rebuild_solr_index
end

desc 'Refresh contribution caches'
task "myexp:refresh:contributions" do
  require File.dirname(__FILE__) + '/config/environment'

  all_viewings = Viewing.find(:all, :conditions => "accessed_from_site = 1").group_by do |v| v.contribution_id end
  all_downloads = Download.find(:all, :conditions => "accessed_from_site = 1").group_by do |v| v.contribution_id end

  Contribution.find(:all).each do |c|
    c.contributable.update_contribution_rank
    c.contributable.update_contribution_rating
    c.contributable.update_contribution_cache

    ActiveRecord::Base.record_timestamps = false

    c.reload
    c.update_attribute(:created_at, c.contributable.created_at)
    c.update_attribute(:updated_at, c.contributable.updated_at)

    c.update_attribute(:site_viewings_count,  all_viewings[c.id]  ? all_viewings[c.id].length  : 0)
    c.update_attribute(:site_downloads_count, all_downloads[c.id] ? all_downloads[c.id].length : 0)

    ActiveRecord::Base.record_timestamps = true
  end
end

desc 'Create a myExperiment data backup'
task "myexp:backup:create" do
  require File.dirname(__FILE__) + '/config/environment'
  Maintenance::Backup.create
end

desc 'Restore from a myExperiment data backup'
task "myexp:backup:restore" do
  require File.dirname(__FILE__) + '/config/environment'
  Maintenance::Backup.restore
end

desc 'Load a SKOS concept schema'
task "myexp:skos:load" do
  require File.dirname(__FILE__) + '/config/environment'

  file_name = ENV['FILE']

  if file_name.nil?
    puts "Missing file name."
    return
  end

  LoadVocabulary::load_skos(YAML::load_file(file_name))
end

desc 'Load an OWL ontology'
task "myexp:ontology:load" do
  require File.dirname(__FILE__) + '/config/environment'

  file_name = ENV['FILE']

  if file_name.nil?
    puts "Missing file name."
    return
  end

  LoadVocabulary::load_ontology(YAML::load_file(file_name))
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

  BioCatalogueImport.import_biocatalogue
end

desc 'Update OAI static repository file'
task "myexp:oai:static" do
  require File.dirname(__FILE__) + '/config/environment'

  # Obtain all public workflows

  workflows = Workflow.find(:all).select do |workflow|
    Authorization.check(:action => 'read', :object => workflow, :user => nil)
  end

  # Generate OAI static repository file

  File::open('public/oai/static.xml', 'wb') do |f|
    f.write(OAIStaticRepository.generate(workflows))
  end
end

desc 'Update topic titles'
task "myexp:topic:update_titles" do
  require File.dirname(__FILE__) + '/config/environment'

  Topic.find(:all).each do |topic|
    topic.update_title
  end
end

desc 'Fix pack timestamps'
task "myexp:pack:fix_timestamps" do
  require File.dirname(__FILE__) + '/config/environment'

  ActiveRecord::Base.record_timestamps = false

  Pack.find(:all).each do |pack|

    timestamps = [pack.updated_at] +
                 pack.contributable_entries.map(&:updated_at) +
                 pack.remote_entries.map(&:updated_at) +
                 pack.relationships.map(&:created_at)

    if pack.updated_at != timestamps.max
      pack.update_attribute(:updated_at, timestamps.max)
    end
  end

  ActiveRecord::Base.record_timestamps = true
end

