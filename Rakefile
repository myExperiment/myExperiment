# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'tasks/rails'

require 'sunspot/rails/tasks'
require 'sunspot/solr/tasks'

begin
  gem 'delayed_job', '~>2.0.4'
  require 'delayed/tasks'
rescue LoadError
  STDERR.puts "Run `rake gems:install` to install delayed_job"
end

desc 'Rebuild Solr index'
task "myexp:refresh:solr" do
  require File.dirname(__FILE__) + '/config/environment'
  Workflow.solr_reindex
  Blob.solr_reindex
  User.solr_reindex
  Network.solr_reindex
  Pack.solr_reindex
end

desc 'Start the search engine'
task "myexp:search:start" do
  require File.dirname(__FILE__) + '/config/environment'

  search_start
end

desc 'Stop the search engine'
task "myexp:search:stop" do
  require File.dirname(__FILE__) + '/config/environment'

  search_stop
end

desc 'Restart the search engine'
task "myexp:search:restart" do
  require File.dirname(__FILE__) + '/config/environment'

  search_stop
  search_start
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

  conn = ActiveRecord::Base.connection

  BioCatalogueImport.import_biocatalogue
end

desc 'Update OAI static repository file'
task "myexp:oai:static" do
  require File.dirname(__FILE__) + '/config/environment'

  # Obtain all public workflows

  workflows = Workflow.find(:all).select do |workflow|
    Authorization.check('view', workflow, nil)
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

desc 'Assign categories to content types'
task "myexp:types:assign_categories" do
  require File.dirname(__FILE__) + '/config/environment'

  workflow_content_types = Workflow.find(:all).group_by do |w| w.content_type_id end.keys

  ContentType.find(:all).each do |content_type|

    next if content_type.category

    if workflow_content_types.include?(content_type.id)
      category = "Workflow"
    else
      category = "Blob"
    end

    content_type.update_attribute("category", category)
  end
end

desc 'Get workflow components'
task "myexp:workflow:components" do
  require File.dirname(__FILE__) + '/config/environment'

  ids = ENV['ID'].split(",").map do |str| str.to_i end

  doc = LibXML::XML::Document.new
  doc.root = LibXML::XML::Node.new("results")

  ids.each do |id|
    components = WorkflowVersion.find(id).components
    components['workflow-version'] = id.to_s
    doc.root << components
  end

  puts doc.to_s
end

desc 'Create initial activities'
task "myexp:activities:create" do
  require File.dirname(__FILE__) + '/config/environment'

  activities = []

  User.find(:all, :conditions => "activated_at IS NOT NULL", :include => :profile).map do |object|
    activities += Activity.new_activities(:subject => object, :action => 'create', :object => object, :timestamp => object.created_at)
    if object.profile.updated_at && object.profile.updated_at != object.profile.created_at
      activities += Activity.new_activities(:subject => object, :action => 'edit', :object => object, :timestamp => object.profile.updated_at)
    end
  end

  (Workflow.all + Blob.all + Pack.all).map do |object|
    activities += Activity.new_activities(:subject => object.contributor, :action => 'create', :object => object, :timestamp => object.created_at)
    if object.updated_at && object.updated_at != object.created_at
      activities += Activity.new_activities(:subject => object.contributor, :action => 'edit', :object => object, :timestamp => object.updated_at)
    end

    object.contribution.policy.permissions.each do |permission|
      activities += Activity.new_activities(:subject => object.contributor, :action => 'create', :object => permission, :timestamp => permission.created_at, :contributable => object)
    end
  end
  
  workflow_versions = (WorkflowVersion.find(:all, :conditions => "version > 1")).select do |object|
    !(object.version == 2 && object.content_blob.data == object.workflow.versions.first.content_blob.data)
  end
  
  workflow_versions.map do |object|
    activities += Activity.new_activities(:subject => object.contributor, :action => 'create', :object => object, :timestamp => object.created_at)
    if object.updated_at && object.updated_at != object.created_at
      activities += Activity.new_activities(:subject => object.contributor, :action => 'edit', :object => object, :timestamp => object.updated_at)
    end
  end
  
  (BlobVersion.find(:all, :conditions => "version > 1")).map do |object|
    activities += Activity.new_activities(:subject => object.blob.contributor, :action => 'create', :object => object, :timestamp => object.created_at)
    if object.updated_at && object.updated_at != object.created_at
      activities += Activity.new_activities(:subject => object.blob.contributor, :action => 'edit', :object => object, :timestamp => object.updated_at)
    end
  end

  Comment.all.each do |comment|
    activities += Activity.new_activities(:subject => comment.user, :action => 'create', :object => comment, :timestamp => comment.created_at)
  end

  Bookmark.all.each do |bookmark|
    activities += Activity.new_activities(:subject => bookmark.user, :action => 'create', :object => bookmark, :timestamp => bookmark.created_at)
  end

  Announcement.all.each do |announcement|
    activities += Activity.new_activities(:subject => announcement.user, :action => 'create', :object => announcement, :timestamp => announcement.created_at)
    if announcement.updated_at && announcement.updated_at != announcement.created_at
      activities += Activity.new_activities(:subject => announcement.user, :action => 'edit', :object => announcement, :timestamp => announcement.updated_at)
    end
  end

  Citation.all.each do |citation|
    activities += Activity.new_activities(:subject => citation.user, :action => 'create', :object => citation, :timestamp => citation.created_at)
    if citation.updated_at && citation.updated_at != citation.created_at
      activities += Activity.new_activities(:subject => citation.user, :action => 'edit', :object => citation, :timestamp => citation.updated_at)
    end
  end

  Rating.all.each do |rating|
    activities += Activity.new_activities(:subject => rating.user, :action => 'create', :object => rating, :timestamp => rating.created_at)
  end

  Review.all.each do |review|
    activities += Activity.new_activities(:subject => review.user, :action => 'create', :object => review, :timestamp => review.created_at)
    if review.updated_at && review.updated_at != review.created_at
      activities += Activity.new_activities(:subject => review.user, :action => 'edit', :object => review, :timestamp => review.updated_at)
    end
  end

  Tagging.all.each do |tagging|
    activities += Activity.new_activities(:subject => tagging.user, :action => 'create', :object => tagging, :timestamp => tagging.created_at)
  end

  Network.all.each do |network|
    activities += Activity.new_activities(:subject => network.owner, :action => 'create', :object => network, :timestamp => network.created_at)
    if network.updated_at && network.updated_at != network.created_at
      activities += Activity.new_activities(:subject => network.owner, :action => 'edit', :object => network, :timestamp => network.updated_at)
    end
  end

  Membership.all.each do |membership|
    if membership.accepted_at
      activities += Activity.new_activities(:subject => membership.user, :action => 'create', :object => membership, :timestamp => membership.accepted_at)
    end
  end
 
  GroupAnnouncement.all.each do |group_announcement|
    activities += Activity.new_activities(:subject => group_announcement.user, :action => 'create', :object => group_announcement, :timestamp => group_announcement.created_at)
  end

  Creditation.all.each do |credit|
    activities += Activity.new_activities(:subject => credit.creditable.contributor, :action => 'create', :object => credit, :timestamp => credit.created_at)
  end

  activities.sort! do |a, b|
    if a.timestamp && b.timestamp
      a.timestamp <=> b.timestamp
    else
      a.object_id <=> b.object_id
    end
  end

  activities.each do |activity|
    activity.save
  end

end

desc 'Synchronize all Atom feeds'
task "myexp:feed:sync:all" do
  require File.dirname(__FILE__) + '/config/environment'

  Feed.all.each do |feed|
    begin
      feed.synchronize!
    rescue
    end
  end
end

desc 'Perform spam analysis on user profiles'
task "myexp:spam:run" do
  require File.dirname(__FILE__) + '/config/environment'
  
  conditions = [[]]

  if ENV['FROM']
    conditions[0] << 'users.id >= ?'
    conditions << ENV['FROM']
  end

  if ENV['TO']
    conditions[0] << 'users.id <= ?'
    conditions << ENV['TO']
  end

  if conditions[0].empty?
    conditions = nil
  else
    conditions[0] = conditions[0].join(" AND ")
  end

  User.find(:all, :conditions => conditions).each do |user|
    user.calculate_spam_score

    if user.save == false
      puts "Unable to save user #{user.id} (spam score = #{user.spam_score})"
    end
  end
end

desc 'Rebuild checksums in the content blob store'
task "myexp:blobstore:checksum:rebuild" do
  require File.dirname(__FILE__) + '/config/environment'

  conn = ActiveRecord::Base.connection

  conn.execute('UPDATE content_blobs SET sha1 = SHA1(data), md5 = MD5(data)')
end

def search_start
  port = YAML.load(File.read("config/sunspot.yml"))[Rails.env]["solr"]["port"]
  `sunspot-solr start -p #{port} -s solr -d solr/data --log-file log/sunspot.log >> log/sunspot-solr.out`
end

def search_stop
  port = YAML.load(File.read("config/sunspot.yml"))[Rails.env]["solr"]["port"]
  `sunspot-solr stop -p #{port}`
end

desc 'Clear RDF cache for research objects'
task "myexp:ro:clean" do
  require File.dirname(__FILE__) + '/config/environment'

  Resource.all.each do |resource|
    unless resource.is_resource
      if resource.content_blob
        resource.content_blob.destroy
        resource.update_attribute(:content_blob, nil)
      end
    end
  end

end

desc 'Ensure all RO enabled models have research objects'
task "myexp:ro:addmissing" do
  require File.dirname(__FILE__) + '/config/environment'

  [Workflow, Blob, Pack].each do |model|
    model.all.each do |record|
      if record.research_object.nil?
        ResearchObject.create(
            :context => record,
            :slug    => "#{Conf.to_visible(model.name)}#{record.id}",
            :user    => record.contributor)
      end
    end
  end
end

desc 'Create the repository to hold RDF triples'
task "myexp:triplestore:create" do
  require File.dirname(__FILE__) + '/config/environment'

  TripleStore.instance.create_repository('myexperiment', 'myexperiment')

  puts 'Done'
end

desc 'Populate the triplestore with RDF for current workflows'
task "myexp:triplestore:populate" do
  require File.dirname(__FILE__) + '/config/environment'

  Workflow.all.each do |workflow|
    workflow.send(:generate_rdf)
    workflow.send(:store_rdf)
    print '.'
  end

  puts "\nDone"
end
