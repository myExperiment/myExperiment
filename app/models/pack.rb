# myExperiment: app/models/pack.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'uri'
require 'zip/zip'
require 'tempfile'
require 'cgi'
require 'sunspot_rails'
require 'has_research_object'

class Pack < ActiveRecord::Base
  
  attr_accessible :title, :description, :license_id, :contributor_type, :contributor_id

  include ResearchObjectsHelper

  after_create :create_research_object

  acts_as_site_entity :owner_text => 'Creator'

  acts_as_contributable
  
  acts_as_bookmarkable
  acts_as_commentable
  acts_as_rateable
  acts_as_taggable
  acts_as_creditable
  acts_as_attributable

  acts_as_doi_mintable('pack', 'Collection')

  has_many :relationships, :dependent => :destroy, :as => :context

  has_many :versions, :class_name => "PackVersion"

  belongs_to :license

  has_research_object

  def find_version(version)
    match = versions.find(:first, :conditions => ["version = ?", version])
    return match if match

    raise ActiveRecord::RecordNotFound.new("Couldn't find Pack with pack_id=#{id} and version=#{version}")
  end

  validates_presence_of :title
  
  format_attribute :description
  
  if Conf.solr_enable
    searchable do
      text :title, :as => 'title', :boost => 2.0
      text :description, :as => 'description'
      text :contributor_name, :as => 'contributor_name'

      text :tags, :as => 'tag' do
        tags.map { |tag| tag.name }
      end

      text :comments, :as => 'comment' do
        comments.map { |comment| comment.comment }
      end
    end
  end

  has_many :contributable_entries,
           :class_name => "PackContributableEntry",
           :foreign_key => :pack_id,
           :conditions => "version IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_many :remote_entries,
           :class_name => "PackRemoteEntry",
           :foreign_key => :pack_id,
           :conditions => "version IS NULL",
           :order => "created_at DESC",
           :dependent => :destroy
  
  def items_count
    contributable_entries.count + remote_entries.count
  end
  
  # returns packs that have largest total number of items
  # the maximum number of results is set by #limit#
  def self.most_items(limit=10)
    self.find_by_sql("SELECT * FROM ((SELECT p.*, contrib.pack_id FROM packs p JOIN pack_contributable_entries contrib ON contrib.pack_id = p.id) UNION ALL (SELECT p.*, remote.pack_id FROM packs p JOIN pack_remote_entries remote ON remote.pack_id = p.id)) AS pack_items GROUP BY pack_id ORDER BY COUNT(pack_id) DESC, title LIMIT #{limit}")
  end
  
  # Returns all the Packs that a contributable is referred to in
  def self.packs_with_contributable(contributable)
    # Use a custom handcrafted sql query (for perf reasons):
    sql = "SELECT packs.*
           FROM packs
           WHERE packs.id IN (
             SELECT pack_id
             FROM pack_contributable_entries
             WHERE contributable_id = ? AND contributable_type = ? )"
  
    return Pack.find_by_sql([ sql, contributable.id, contributable.class.to_s ])
  end
  
  def self.archive_folder
    # single declaration point of where the zip archives for downloadable packs would live
    return "tmp/packs"
  end
  
  def archive_file(no_timestamp=false)
    # the name of the zip file, where contents of current pack will be placed
    filename =  "[PACK] #{self.title.gsub(/[^\w\.\-]/,'_').downcase}"
    filename += (no_timestamp ? "*" :  " - #{Time.now.strftime('%Y-%m-%d @ %H%M')}")
    filename += ".zip"
    return filename
  end
  
  def archive_file_path(no_timestamp=false)
    # "#{Conf.base_uri}/packs/#{id}/download/pack_#{id}.zip"
    return(Pack.archive_folder + "/" + archive_file(no_timestamp))
  end
  
  
  def create_zip(user, list_images_hash)
    
    # VARIABLE DECLARATIONS
    
    # item counters
    self_downloaded_items_cnt = 0
    self_downloaded_workflow_cnt = 0
    self_downloaded_file_cnt = 0
    self_view_only_workflow_cnt = 0
    self_view_only_file_cnt = 0
    self_pack_cnt = 0 # pack are always view-only (as download of nested packs is not supported)
    self_hidden_items_cnt = 0 # items with no viewing permissions
    self_internal_items_cnt = self.contributable_entries.length 
    self_external_items_cnt = self.remote_entries.length
    self_total_items_cnt = self_internal_items_cnt + self_external_items_cnt
    
    # pack description containers
    pack_data_html = ""
    pack_details_html = ""
    internal_items_downloaded_html = ""
    internal_items_viewing_only_html = ""
    internal_items_packs_html = ""
    internal_items_hidden_html = ""
    external_items_html = "" # are always in 'not downloaded' section - as these are just links
    
    pack_data_txt = ""
    internal_items_downloaded_txt = ""
    internal_items_viewing_only_txt = ""
    internal_items_packs_txt = ""
    internal_items_hidden_txt = ""
    external_items_txt = ""  # are always in 'not downloaded' section - as these are just links
    
    
    # ========= PACK DESCRIPTION ===========
    #
    # plain-TEXT
    # generate pack description data (which will be put into a text file in the archive)
    pack_data_txt = "********** Snapshot of the Pack: #{self.title} **********\n\n"
    pack_data_txt += "Downloaded from #{Conf.sitename}\n"
    pack_data_txt += "Snapshot generated at " + Time.now.strftime("%H:%M:%S on %A, %d %B %Y") + "\n\n\n\n"
    pack_data_txt += "========== Pack Details ==========\n\n"
    pack_data_txt += "Title: #{self.title}"
    pack_data_txt += "\nItems: #{self_total_items_cnt}"
    pack_data_txt += "\nLocation: #{location_string("pack", self.id)}"
    pack_data_txt += "\nCreated by: " + uploader_string(self.contributor_type, self.contributor_id, false, false)
    pack_data_txt += "\nCreated at: " + self.created_at.strftime("%H:%M:%S on %A, %d %B %Y")
    pack_data_txt += "\nLast updated at: " + self.updated_at.strftime("%H:%M:%S on %A, %d %B %Y")
    pack_data_txt += "\n\nDescription: " + (self.description.nil? || self.description.empty? ? "none" : "\n\n" + prepare_description(self.description) )
    #
    # HTML
    cgi = CGI.new("html4")
    pack_details_html = cgi.div("class" => "pack_metadata") do
      cgi.div("class" => "pack_details") do
        cgi.h2 {"Pack Details"} +
        cgi.table() {
          cgi.tr() { cgi.td{"Title"} + cgi.td{cgi.a(location_string("pack", self.id)){self.title}} } +
          cgi.tr() { cgi.td{"Items"} + cgi.td{self_total_items_cnt} } +
          cgi.tr() { cgi.td{"Created by"} + cgi.td{uploader_string(self.contributor_type, self.contributor_id, true, false)} } +
          cgi.tr() { cgi.td{"Created at"} + cgi.td{self.created_at.strftime("%H:%M:%S on %A, %d %B %Y")} } +
          cgi.tr() { cgi.td{"Last updated at"} + cgi.td{self.updated_at.strftime("%H:%M:%S on %A, %d %B %Y")} }
        }
      end +
      cgi.div("class" => "pack_description") do
        cgi.h3 {"Description"} +
        cgi.p { (self.description_html.nil? || self.description_html.empty? ? "none" : self.description_html ) }
      end
    end
    
    
    # ========= CREATE THE ZIP FILE & WRITE ALL PACK ENTRIES INTO IT ===========
    # (also collect metadata about all the entries in plain text and HTML formats)
    
    # check if the temp folder for storing packs exists
    FileUtils.mkdir(Pack.archive_folder) if not File.exists?(Pack.archive_folder)
    
    # check to see if the file exists already, and if it does, delete it
    # (regular expression needed to take care of timestamps)
    FileUtils.rm Dir.glob(archive_file_path(true).gsub(/[\[\]]/, "?")), :force => true

    # create the zip file
    zipfile = Zip::ZipFile.open(archive_file_path, Zip::ZipFile::CREATE)
      # now add all pack items to the zip archive
      item = nil
    
      # will keep a list of all filenames that are put into the archive (to delete temp files later)
      zip_filenames = []
      
      # will help to save filesystem calls on checking whether the folder for workflows/files was already created
      workflows_folder_created = false
      files_folder_created = false
           
      # start with internal items
      self.contributable_entries.each { |item_entry|
        # the first thing to do with each item is to check if download is allowed
        item_contribution = Contribution.find(:first, :conditions => ["contributable_type = ? AND contributable_id = ?", item_entry.contributable_type, item_entry.contributable_id])
        
        # check if the item to which this entry points to still exists
        if item_contribution.nil?
          self_hidden_items_cnt += 1
          internal_items_hidden_html += generate_hidden_item_data("html", cgi, item_entry, true)
          internal_items_hidden_txt  += generate_hidden_item_data("text", nil, item_entry, true)
          next # skips all further processing and moves on to the next item
        end
        
        download_allowed = Authorization.check('download', item_contribution, user)
        viewing_allowed = download_allowed ? true : Authorization.check('view', item_contribution, user)
        
        
        case item_entry.contributable_type.downcase
          when "workflow"
            # if 'contributable_version' in pack entry says 'NULL' - means the latest version that is available;
            # otherwise choose a version specified by 'contributable_version'
            item = Workflow.find(item_entry.contributable_id)
            is_current_version = true
            if item_entry.contributable_version
              wf_version = item_entry.contributable_version
              is_current_version = false if (wf_version != item.versions.length)
            else
              wf_version = item.current_version # (and 'is_current_version' already reflects this by default)
            end
            
            # need to check if we have to obtain another (not the latest) version of the workflow
            # (still have to keep pointer to the latest version, which is in 'item' at the moment -
            #  in case if the required version will not be found, that will help to display the right 'item missing' message) 
            required_item_version = (is_current_version ? item : item.find_version(wf_version)) 
            
            # 'required_item_version' now points to the right version of workflow -> add its data to ZIP & create description in HTML and text formats;
            # (just checking that that version was really found - if not, add nothing to archive & display right error message)
            if required_item_version
              if download_allowed
                self_downloaded_items_cnt += 1
                self_downloaded_workflow_cnt += 1
                zip_filenames << item.filename(wf_version)
                
                unless workflows_folder_created
                  zipfile.mkdir("workflows")
                  workflows_folder_created = true
                end
                zipfile.get_output_stream( "workflows/" + item.filename(wf_version)) { |stream| stream.write(required_item_version.content_blob.data)}
                
                internal_items_downloaded_html += generate_workflow_data("html", cgi, item_entry, item, required_item_version, wf_version, true)
                internal_items_downloaded_txt  += generate_workflow_data("text", nil, item_entry, item, required_item_version, wf_version, true)
              elsif viewing_allowed
                # only viewing is allowed, but can't download - metadata still displayed in full
                self_view_only_workflow_cnt += 1
                internal_items_viewing_only_html += generate_workflow_data("html", cgi, item_entry, item, required_item_version, wf_version, false)
                internal_items_viewing_only_txt  += generate_workflow_data("text", nil, item_entry, item, required_item_version, wf_version, false)
              else
                # neither download, nor viewing allowed - display 'hidden item' and who/when added it to the pack
                self_hidden_items_cnt += 1
                internal_items_hidden_html += generate_hidden_item_data("html", cgi, item_entry)
                internal_items_hidden_txt  += generate_hidden_item_data("text", nil, item_entry)
              end
              
            # ELSE - version was not found; display error  
            else
              if viewing_allowed
                # only viewing is allowed, but can't download - some metadata still displayed, subject to availability (the WF version is missing!!) 
                self_view_only_workflow_cnt += 1
                internal_items_viewing_only_txt += "+ Workflow: #{item.title} ( !! a specific version of this workflow that the pack entry points to was not found !! )\n"
                internal_items_viewing_only_txt += "  Version: #{wf_version}\n"
                internal_items_viewing_only_txt += "  #{item_comment_string(item_entry, false)}\n\n"
                
                internal_items_viewing_only_html += cgi.li("class" => "denied"){ 
                  cgi.div("class" => "workflow_item") do
                    cgi.div("class" => "item_data") do
                      "<b>Workflow: </b>" + item.title + " (<font style='color: red;'> a specific version of the workflow that the pack enty point to was not found </font>)<br/>" +
                      "Version: #{wf_version}"
                    end
                  end
                }
              else
                # neither download, nor viewing allowed - display 'hidden item' and who/when added it to the pack
                self_hidden_items_cnt += 1
                internal_items_hidden_html += generate_hidden_item_data("html", cgi, item_entry)
                internal_items_hidden_txt  += generate_hidden_item_data("text", nil, item_entry)
              end
            end

          when "blob"
            item = Blob.find(item_entry.contributable_id)
            
            if download_allowed
              self_downloaded_items_cnt += 1
              self_downloaded_file_cnt += 1
              zip_filenames << item.local_name
              
              unless files_folder_created
                zipfile.mkdir("files")
                files_folder_created = true
              end
              zipfile.get_output_stream("files/" + item.local_name) { |stream| stream.write(ContentBlob.find(item.content_blob_id).data) }
              
              internal_items_downloaded_html += generate_file_data("html", cgi, item_entry, item, true)
              internal_items_downloaded_txt  += generate_file_data("text", nil, item_entry, item, true)
            elsif viewing_allowed
              # only viewing is allowed, but can't download - metadata still displayed in full
              self_view_only_file_cnt += 1
              internal_items_viewing_only_html += generate_file_data("html", cgi, item_entry, item, false)
              internal_items_viewing_only_txt  += generate_file_data("text", nil, item_entry, item, false)
            else
              # neither download, nor viewing allowed - display 'hidden item' and who/when added it to the pack
              self_hidden_items_cnt += 1
              internal_items_hidden_html += generate_hidden_item_data("html", cgi, item_entry)
              internal_items_hidden_txt  += generate_hidden_item_data("text", nil, item_entry)
            end
            
          when "pack"
            item = Pack.find(item_entry.contributable_id)
            
            # download of nested packs is not supported anyway, so just check if viewing is allowed
            # ('download_allowed' will be passed through, however, to display a separate download link for the pack, if allowed) 
            if viewing_allowed
              self_pack_cnt += 1
              # download_allowed value was not checked before (as for workflows and files), so pass variable here, not particular value
              internal_items_packs_html += generate_pack_data("html", cgi, item_entry, item, download_allowed)
              internal_items_packs_txt  += generate_pack_data("text", nil, item_entry, item, download_allowed)
            else
              self_hidden_items_cnt += 1
              internal_items_hidden_html += generate_hidden_item_data("html", cgi, item_entry)
              internal_items_hidden_txt  += generate_hidden_item_data("text", nil, item_entry)
            end
            
        end
        
        # finished processing current item, carry on with the next one
      }
      
      
      # continue with external items
      # NOTE: there are no viewing/download restrictions on any of the external items
      self.remote_entries.each { |remote_item|
        external_items_html += generate_external_item_data("html", cgi, remote_item)
        external_items_txt  += generate_external_item_data("text", nil, remote_item)
      }
      
      
      # ASSEMBLE ALL PARTS OF TEXT AND HTML DESCRIPTION FILES
      #
      # TEXT
      #
      # assemble pack data & item data together; also add date & 'downloaded from'
      pack_data_txt += "\n\n\n\n========== Summary of Pack Items (#{self_total_items_cnt.to_s}) ==========\n\n"
      pack_data_txt += "Total number of items in the pack: " + self_total_items_cnt.to_s + "\n\n"
      pack_data_txt += "Downloaded items: #{self_downloaded_items_cnt}\n"
      pack_data_txt += "     |-  Workflows: #{self_downloaded_workflow_cnt}\n"
      pack_data_txt += "     |-  Files    : #{self_downloaded_file_cnt}\n\n"
      pack_data_txt += "Not downloaded items: #{self_total_items_cnt - self_downloaded_items_cnt}\n"
      pack_data_txt += "     |- Packs         : #{self_pack_cnt} (download of nested packs is not supported)\n"
      pack_data_txt += "     |- External items: #{self_external_items_cnt}\n"
      pack_data_txt += "     |- Items that can be viewed, but not downloaded: #{self_view_only_workflow_cnt + self_view_only_file_cnt} (view-only permissions)\n"
      pack_data_txt += "         |- Workflows : #{self_view_only_workflow_cnt}\n"
      pack_data_txt += "         |- Files     : #{self_view_only_file_cnt}\n"
      pack_data_txt += "     |- Items that cannot be viewed : #{self_hidden_items_cnt}\n"
      
      pack_data_txt += "\n\n\n========== Downloaded Items (#{self_downloaded_items_cnt}) ==========\n\n" + (self_downloaded_items_cnt == 0 ? "    // No items were downloaded //\n\n" : internal_items_downloaded_txt)
      pack_data_txt += "\n\n========== Not Downloaded Items (#{self_total_items_cnt - self_downloaded_items_cnt}) ==========\n"
      pack_data_txt += "\n\n=== Packs within this pack (#{self_pack_cnt}) ===\n\n" + (self_pack_cnt == 0 ? "    // None //\n\n" : internal_items_packs_txt)
      pack_data_txt += "\n\n=== External items (#{self_external_items_cnt}) ===\n\n" + (self_external_items_cnt == 0 ? "    // None //\n\n" : external_items_txt)
      pack_data_txt += "\n\n=== Items that can be viewed, but not downloaded (#{self_view_only_workflow_cnt + self_view_only_file_cnt}) ===\n\n" + (internal_items_viewing_only_txt.blank? ? "    // None //\n\n" : internal_items_viewing_only_txt)
      pack_data_txt += "\n\n=== Items that cannot be viewed (#{self_hidden_items_cnt}) ===\n\n" + (self_hidden_items_cnt == 0 ? "    // None //\n\n" : internal_items_hidden_txt)
      #
      # HTML
      pack_data_html = cgi.html{
        cgi.head{ 
          cgi.title{"Snapshot of the Pack: #{self.title} (from #{Conf.sitename})"} +
          cgi.link("href" => "index.css", "media" => "screen", "rel" => "Stylesheet", "type" => "text/css")
        } +
        cgi.body{
          cgi.div("class" => "provider_info") do
            cgi.h1{"Snapshot of the Pack: #{cgi.a(location_string("pack", self.id)){self.title}}"} +
            cgi.p{
              cgi.i{"Downloaded from #{cgi.a(Conf.base_uri){Conf.sitename}} website<br/><br/>" +
              "Snapshot generated at " + Time.now.strftime("%H:%M:%S on %A, %d %B %Y")} 
            }
          end +
          pack_details_html +
          
          cgi.br +
          cgi.div("class" => "pack_items_summary") do
            cgi.h2{"Summary of Pack Items (#{self_total_items_cnt})"} +
            cgi.ul {
              cgi.li{cgi.a("#downloaded_items"){"Downloaded items:"} + " #{self_downloaded_items_cnt}" +
                cgi.table{
                  cgi.tr{ cgi.td{"Workflows:"} + cgi.td{self_downloaded_workflow_cnt} } +
                  cgi.tr{ cgi.td{"Files:"} + cgi.td{self_downloaded_file_cnt} }
                }
              } +
              cgi.li{cgi.a("#not_downloaded_items"){"Not downloaded items:"} + " #{self_total_items_cnt - self_downloaded_items_cnt}" +
                cgi.table{
                  cgi.tr{ cgi.td{cgi.a("#packs"){"Packs within this pack:"}} + cgi.td{self_pack_cnt} } +
                  cgi.tr{ cgi.td{cgi.a("#external_items"){"External items:"}} + cgi.td{self_external_items_cnt} } +
                  cgi.tr{ cgi.td{cgi.a("#viewing_only_items"){"Items that can be viewed, but not downloaded:"}} + cgi.td{"#{self_view_only_workflow_cnt + self_view_only_file_cnt}; ( #{self_view_only_workflow_cnt} workflows, #{self_view_only_file_cnt} files )"} } +
                  cgi.tr{ cgi.td{cgi.a("#hidden_items"){"Items that cannot be viewed:"}} + cgi.td{self_hidden_items_cnt} }
                }
              }
            }
          end +
          cgi.br +
          cgi.div("class" => "pack_items") do
            
            cgi.div("class" => "pack_downloaded_items") do
              cgi.a("name" => "#downloaded_items") +
              cgi.h2{"Downloaded Items (#{self_downloaded_items_cnt})"} +
              (internal_items_downloaded_html.blank? ?
               none_text_html_message("No items were downloaded") :
               cgi.ul { internal_items_downloaded_html }
              )
            end +
            
            cgi.br +
            cgi.div("class" => "pack_not_downloaded_items") do
              cgi.a("name" => "#not_downloaded_items") +
              cgi.h2{"Not Downloaded Items (#{self_total_items_cnt - self_downloaded_items_cnt})"} +
              
              cgi.div("class" => "pack_pack_items") do
                cgi.a("name" => "#packs") +
                cgi.h3{"Packs within this pack (#{self_pack_cnt})"} +
                (internal_items_packs_html.blank? ?
                 none_text_html_message("None") :
                 cgi.ul{ internal_items_packs_html }
                )
              end +
              
              cgi.div("class" => "pack_external_items") do
                cgi.a("name" => "#external_items") +
                cgi.h3{"External items (#{self_external_items_cnt})"} +
                (external_items_html.blank? ?
                 none_text_html_message("None") :
                 cgi.ul { external_items_html }
                )
              end +
              
              cgi.div("class" => "pack_viewing_only_items") do
                cgi.a("name" => "#viewing_only_items") +
                cgi.h3{"Items that can be viewed, but not downloaded (#{self_view_only_workflow_cnt + self_view_only_file_cnt})"} +
                (internal_items_viewing_only_html.blank? ?
                 none_text_html_message("None") : 
                 cgi.ul{ internal_items_viewing_only_html }
                )
              end +
              
              cgi.div("class" => "pack_hidden_items") do
                cgi.a("name" => "#hidden_items") +
                cgi.h3{"Items that cannot be viewed (#{self_hidden_items_cnt})"} +
                (internal_items_hidden_html.blank? ?
                 none_text_html_message("None") :
                 cgi.ul { internal_items_hidden_html }
                )
              end
            end
            
          end
        }
      }
      
      # STORE DESCRIPTION DATA IN RELEVANT FILES
      #
      # TEXT
      # put pack data into temporary file & add it to archive; then delete
      info = Tempfile.new("pack_#{self.id}.tmp")
      info.write(pack_data_txt)
      info.close()
      zipfile.add("_Pack Info.txt", info.path)
      #
      # HTML
      index = Tempfile.new("index.html.tmp")
      index.write(CGI::pretty(pack_data_html))
      index.close()
      zipfile.add("index.html", index.path)
      #
      # CSS
      zipfile.add("index.css", "./public/stylesheets/pack-snapshot.css")
      #
      # LIST BULLET IMAGES
      zipfile.mkdir("_images")
      zipfile.add("_images/workflow.png", list_images_hash["workflow"])
      zipfile.add("_images/file.png", list_images_hash["file"])
      zipfile.add("_images/pack.png", list_images_hash["pack"])
      zipfile.add("_images/link.png", list_images_hash["link"])
      zipfile.add("_images/denied.png", list_images_hash["denied"])
      
   
   # finalize the archive file
   zipfile.close()

   # set read permissions on the zip file
   File.chmod(0644, archive_file_path)
   
   # remove any temporary files that were created while creating the zip file
   # (these are created in the same place, where the zip file is stored)
   zip_filenames.each do |temp_file|
     FileUtils.rm Dir.glob(Pack.archive_folder + "/" + "#{temp_file}.*"), :force => true # 'force' option makes sure that exceptions are never raised
   end
   
    
  end
  
  
  # Resolves the link provided... identifies what internal entry type it corresponds to and creates the appropriate entry object (BUT DOES NOT SAVE IT)...
  # - if the link points to something internally on this site it will attempt to find that item and then create a new pack_contributable_entry for it (in the event that it doesn't find the item it will treat the URI as an external one and create a pack_remote_entry).
  # - if the URI is clearly not referring to this site, it will create a pack_remote_entry.
  #
  # Input parameters:
  # - link: a string based uri beginning with the protocol (eg: "http://...").
  # - host_name: the host name that this site uses (e.g: "www.myexperiment.org").
  # - host_port: the host port that this site runs on (must be a string; e.g: "80" or nil).
  # - current_user: the currently logged on user.
  #
  # Returns an array - [errors, type, entry] where:
  # - errors: an ActiveRecord::Errors object; the high level errors that have occurred in processing the link. If this contains errors than it means no entry was created and no type was determined.
  # - type: a String; the canonical type the link was able to be resolved to (currently 'contributable' or 'remote').
  # - entry: a NEW and UNSAVED pack entry object that link would be saved as.
  def resolve_link(link, host_name, host_port, current_user)
    errors_here = Pack.new.errors
    type = nil
    entry = nil
    is_remote = false

    begin
      uri = URI.parse(link)

      if uri.relative? || (uri.absolute? && is_internal_uri?(uri, host_name, host_port))
        # Attempt to initialise a pack_contributable_entry
        contributable = nil

        # Use Rails' routing to figure out the URL
        begin
          request = Rails.application.routes.recognize_path(uri.path, :method => :get)
          model_name = request[:controller].classify
        rescue ActionController::RoutingError
          raise URI::InvalidURIError
        end

        if Conf.contributable_models.include?(model_name) && request[:action] == "show"
          contributable = eval(model_name).find_by_id(request[:id])
        else
          is_remote = true # Treat as a remote entry
        end

        if !is_remote
          if contributable && errors_here.empty?
            entry = PackContributableEntry.new
            entry.contributable = contributable
  
            type = 'contributable'
  
            # check if the 'contributable' is a pack, then that it's not the same pack,
            # to which we are trying to add something at the moment
            if contributable == self.id
              errors_here.add(:base, 'Cannot add the pack to itself')
            end
  
            # Check if version was specified in the uri
            entry.contributable_version = request[:version]
  
            # maybe it was as a query instead?
            if uri.query
              entry.contributable_version = CGI.parse(uri.query)["version"].first.try(:to_i)
            end
          else
            errors_here.add(:base, 'The item the link points to does not exist.')
          end
        end
      else
        is_remote = true # Treat as a remote entry
      end

      if is_remote
        entry = PackRemoteEntry.new(:title => "Link", :uri => link)
        type = 'remote'
      end

      if entry
        entry.pack = self
        entry.user = current_user
      end

    rescue URI::InvalidURIError
      errors_here.add(:base, 'Really struggled to parse this link. Please could you check if it is valid.')
    end

    return [errors_here, type, entry]
  end
  
  
  # Checks if the uri provided points to something internally to the host site. 
  # Note: assumes that the host site runs on HTTP.
  def is_internal_uri?(uri, host_name, host_port)
    return ((uri.scheme == "http") && (uri.host == host_name) && (uri.port.to_s == host_port)) 
  end
  
  
  # strips out all unnecessary html, preserving special characters and new lines
  def prepare_description(description)
    # replace all the new line equivalents in html with \n's
    desc = description.gsub(/<br\/?>/, "\n")
    desc = desc.gsub("<p></p>", "\n")
    
    # strip out all the rest of html tags
    desc = desc.gsub(/<\/?[^>]*>/,  "")
    desc = desc.gsub("&nbsp;", "")
    
    # decode all special character symbols back into text
    return CGI::unescapeHTML(desc)
  end
  
  def contributables
    contributable_entries.map do |e| e.contributable end
  end

  # This function takes a string, such as 'contributable:4' (which would return
  # a PackContributableEntry with the id of 4) or 'remote:8' (which would
  # return a PackRemoteEntry with an id of 8) and returns the appropriate pack
  # item if this pack contains that item.

  def find_pack_item(str)

    thing_type, thing_id = str.split(":")

    case thing_type
      when 'contributable'
        ob = PackContributableEntry.find(:first,
            :conditions => ['id = ? AND pack_id = ?', thing_id, id])

      when 'remote'
        ob = PackRemoteEntry.find(:first,
            :conditions => ['id = ? AND pack_id = ?', thing_id, id])
    end
  end

  # This method determines which pack relationships refer to contributables
  # that are not included as pack entries in this pack.  Such relationships
  # might occur when deleting entries from a pack.

  def dangling_relationships
    relationships.select do |relationship|
      relationship.subject.nil? || relationship.objekt.nil?
    end
  end

  def statistics_for_rest_api
    APIStatistics.statistics(self)
  end
 
  def snapshot!
  
    self.current_version = self.current_version ? self.current_version + 1 : 1

    inhibit_timestamps do
 
      pack_entry_map = {}
      resource_map = {}

      new_pack_version = versions.build(
          :version          => current_version,
          :contributor      => contributor,
          :title            => title,
          :description      => description,
          :description_html => description_html)

      contributable_entries.each do |entry|

        pack_entry_map[entry] = new_pack_version.contributable_entries.build(
            :pack => self,
            :contributable_id => entry.contributable_id,
            :contributable_type => entry.contributable_type,
            :contributable_version => entry.contributable_version,
            :comment => entry.comment,
            :user_id => entry.user_id,
            :version => current_version,
            :created_at => entry.created_at,
            :updated_at => entry.updated_at)
      end

      remote_entries.each do |entry|

        pack_entry_map[entry] = new_pack_version.remote_entries.build(
            :pack => self,
            :title => entry.title,
            :uri => entry.uri,
            :alternate_uri => entry.alternate_uri,
            :comment => entry.comment,
            :user_id => entry.user_id,
            :version => current_version,
            :created_at => entry.created_at,
            :updated_at => entry.updated_at)
      end

      # Calculate new research object version index

      new_research_object = new_pack_version.build_research_object(
          :slug => "#{research_object.slug}v#{current_version}",
          :version => current_version,
          :user => contributor)

      research_object.resources.each do |resource|

        new_resource = new_research_object.resources.build(
          :context => resource.context,
          :sha1 => resource.sha1,
          :size => resource.size,
          :content_type => resource.content_type,
          :path => resource.path,
          :entry_name => resource.entry_name,
          :creator_uri => resource.creator_uri,
          :proxy_in_path => resource.proxy_in_path,
          :proxy_for_path => resource.proxy_for_path,
          :ao_body_path => resource.ao_body_path,
          :resource_map_path => resource.resource_map_path,
          :aggregated_by_path => resource.aggregated_by_path,
          :is_resource => resource.is_resource,
          :is_aggregated => resource.is_aggregated,
          :is_proxy => resource.is_proxy,
          :is_annotation => resource.is_annotation,
          :is_resource_map => resource.is_resource_map,
          :is_folder => resource.is_folder,
          :is_folder_entry => resource.is_folder_entry,
          :is_root_folder => resource.is_root_folder,
          :created_at => resource.created_at,
          :updated_at => resource.updated_at,
          :uuid => resource.uuid
          #:title => resource.title # This breaks snapshotting with a missing method: 'title' error
        )

        resource_map[resource] = new_resource

        if resource.content_blob
          new_resource.build_content_blob(:data => resource.content_blob.data)
        end

      end

      research_object.annotation_resources.each do |annotation_resource|
        
        new_research_object.annotation_resources.build(
          :annotation => resource_map[annotation_resource.annotation],
          :resource_path => annotation_resource.resource_path)

      end
 
    end
    
    save

  end

  def describe_version(version_number)
    return "" if versions.count < 2
    return "(earliest)" if version_number == versions.first.version
    return "(latest)" if version_number == versions.last.version
    return ""
  end

  scope :component_families, :include => :tags, :conditions => "tags.name = 'component family'"

  def component_family?
    tags.any? { |t| t.name == 'component family' }
  end

  def component_profile
    entry = contributable_entries.detect { |e| e.contributable_type == 'Blob' && e.contributable && e.contributable.component_profile? }
    if entry
      profile = entry.contributable
      if entry.contributable_version
        profile.find_version(entry.contributable_version)
      else
        profile
      end
    else
      nil
    end
  end

  protected
  
  # produces html string containing the required messaged, enclosed within left-padded P tag, belonging to 'none_text' class
  # (with a vertical spacing below the message as well) 
  def none_text_html_message(msg)
    return "<p style='margin-left: 2em; margin-bottom: 1.5em;' class='none_text'>#{msg}</p>"
  end
  
  
  # just a helper method for packing items into a zip:
  # displays '(Uploader: X' string for each item, where X is a link to myExperiment account of that user
  # (link created only when 'html_required' is set to 'true')
  def uploader_string(contributor_type, contributor_id, html_required, show_leading_text=true)
    res = show_leading_text ? "Uploader: " : ""
    
    case contributor_type.downcase
      when "user"
        user = User.find(contributor_id)
        if html_required
          res += "<a href=#{Conf.base_uri}/users/#{contributor_id}>#{user.name}</a>"
        else
          res += user.name + " (profile: #{Conf.base_uri}/users/#{contributor_id})"
        end
      when "network"
        group = Network.find(contributor_id)
        if html_required
          res += "<a href=#{Conf.base_uri}/groups/#{contributor_id}>\"#{group.title}\" group</a>"
        else
          res += group.title + " (profile: #{Conf.base_uri}/groups/#{contributor_id})"
        end
      else
        res += "unknown (contributor_type: #{contributor_type}; contributor_id: #{contributor_id})"
    end
    
    return res
  end
  
  
  # a helper to return the link to a resource based on type, id & version 
  # (version is NIL by default - means no version, or the latest one)
  def location_string(type, id, version=nil)
    link = Conf.base_uri
    case type.downcase
      when "workflow"; link += "/workflows/"
      when "blob";     link += "/files/"
      when "pack";     link += "/packs/"
      else;            return( link += "/home" )
    end
    
    link += id.to_s
    link += "?version=#{version}" if version
    
    return link
  end
  
  
  # a helper to print out comments for some item
  def item_comment_string(item, html_required)
    return "" if item.nil?
    
    if item.comment.nil? || item.comment.blank?
      return "Comment: " + (html_required ? "<span class='none_text'>none</span>" : "none")
    else
      return "Comment: " + (html_required ? "<div class='comment_text'>#{white_list(simple_format(item.comment))}</div>" : ("\n  |   " + item.comment.gsub(/\n/, "\n  |   ")))
    end
  end
  
  
  # *********************************************************************
  
  # A helper method used to generate metadata for all the pack item types;
  # see below for explanation on the input parameters.
  def generate_item_metadata(format, cgi, item_entry)
    item_metadata = ""
    
    case format.downcase
      when "html"
        item_metadata += cgi.div("class" => "item_metadata") do
          "Added to pack by: " + uploader_string("user", item_entry.user_id, true, false) + " (#{item_entry.created_at.strftime('%d/%m/%Y @ %H:%M:%S')})<br/>" +
          item_comment_string(item_entry, true)
        end
      when "text"
        item_metadata += "  | Added to pack by: " + uploader_string("user", item_entry.user_id, false, false) + "; added on (#{item_entry.created_at.strftime('%d/%m/%Y @ %H:%M:%S')})\n"
        item_metadata += "  | " + item_comment_string(item_entry, false) + "\n\n"
      else
        return "ERROR" 
    end
    
    return item_metadata
  end
  
  
  
  # Helper methods that follow have the same (or very similar set of input parameters) and are used for the same purpose -
  # to generate a description of an appropriate type (hence multiple methods - one for each type) of pack items in the
  # required format.
  #
  # Input parameters:
  # 1) format - "html|text";
  # 2) cgi - instance of a CGI class set to generate HTML code;
  # 3) item_entry - entry in 'pack_contributable_entries' or 'pack_remote_entries' table for current item;
  # 4) item - for contributable entries (workflows, files, packs), this is the actual item object;
  # 5) required_item_versio - this is the pointer to a required version of the object (used only for versioned contributables - only workflows for now);
  # 6) wf_version - number representing the required version of the object (used only for versioned contributables - only workflows for now);
  # 7) download_allowed - boolean parameter specifying whether current user can download this item or not;
  #
  # Return value:
  # a string with text/html description of the item (given that it can/can't be downloaded by current user)
  
  
  # for workflows in the pack
  def generate_workflow_data(format, cgi, item_entry, item, required_item_version, wf_version, download_allowed)
    workflow_data = ""
    workflow_metadata = generate_item_metadata(format, cgi, item_entry)
    
    case format.downcase
      when "html"
        workflow_data += cgi.li("class" => "workflow"){
          cgi.div("class" => "workflow_item") do
            cgi.div("class" => "item_data") do
              "<b>Workflow: </b>" + cgi.a(location_string(item_entry.contributable_type, item.id, wf_version)){required_item_version.title} + 
              (download_allowed ? ("&nbsp;&nbsp;&nbsp;[ " + cgi.a("./workflows/" + item.filename(wf_version)){"open local copy"} + " ]") : "") + "<br/>" +
              "Type: <span class='workflow_type'>" + item.type_display_name() + "</span><br/>" +
              "Originally uploaded by: " + uploader_string(item.contribution.contributor_type, item.contribution.contributor_id, true, false) + "<br/>" +
              "Version: #{wf_version} (created on: #{required_item_version.created_at.strftime("%d/%m/%Y")}, last edited on: #{required_item_version.updated_at.strftime("%d/%m/%Y")})<br/>" +
              "Version uploaded by: " + uploader_string(required_item_version.contributor_type, required_item_version.contributor_id, true, false) + "<br/>"
            end +
            workflow_metadata 
          end
        }
        
      when "text"
        workflow_data += "+ Workflow: #{item.title}"
        if download_allowed
          workflow_data += " (local copy: workflows/#{item.filename(wf_version)})"
        end
        workflow_data += "\n  Type: " + item.type_display_name()
        workflow_data += "\n  Location: " + location_string(item_entry.contributable_type, item.id, wf_version)
        workflow_data += "\n  Originally uploaded by: " + uploader_string(item.contribution.contributor_type, item.contribution.contributor_id, false, false)
        workflow_data += "\n  Version: #{wf_version} (created on: #{required_item_version.created_at.strftime("%d/%m/%Y")}, last edited on: #{required_item_version.updated_at.strftime("%d/%m/%Y")})"
        workflow_data += "\n  Version uploaded by: " + uploader_string(required_item_version.contributor_type, required_item_version.contributor_id, false, false) + "\n"
        workflow_data += workflow_metadata
      else
        return "ERROR"
    end
    
    return workflow_data
  end
  
  
  # for files (aka 'blobs') in the pack
  def generate_file_data(format, cgi, item_entry, item, download_allowed)
    file_data = ""
    file_metadata = generate_item_metadata(format, cgi, item_entry)
    
    case format.downcase
      when "html"
        file_data += cgi.li("class" => "file"){ 
          cgi.div("class" => "file_item") do
            cgi.div("class" => "item_data") do
              "<b>File: </b>" + cgi.a(location_string(item_entry.contributable_type, item.id)){item.title} + 
              (download_allowed ? ("&nbsp;&nbsp;&nbsp;[ " + cgi.a("./files/" + item.local_name){"open local copy"} + " ]") : "") + "<br/>" +
              uploader_string(item.contributor_type, item.contributor_id, true) + "<br/>"
            end +
            file_metadata
          end
        }
      
      when "text"
        file_data += "+ File: #{item.title}"
        if download_allowed
          file_data += " (local copy: files/#{item.local_name})"
        end
        file_data += "\n  Location: " + location_string(item_entry.contributable_type, item.id)
        file_data += "\n  " + uploader_string(item.contributor_type, item.contributor_id, false) + "\n"
        file_data += file_metadata
        
      else
        return "ERROR"
    end
    
    return file_data
  end


  # for packs that are contained within the pack
  def generate_pack_data(format, cgi, item_entry, item, download_allowed)
    pack_data = ""
    pack_metadata = generate_item_metadata(format, cgi, item_entry)
    
    case format.downcase
      when "html"
        pack_data += cgi.li("class" => "pack"){
          cgi.div("class" => "pack_item") do
            cgi.div("class" => "item_data") do
              "<b>Pack: </b>" + cgi.a(location_string(item_entry.contributable_type, item.id)){item.title} + 
              (download_allowed ? ("&nbsp;&nbsp;&nbsp;[ #{cgi.a(location_string(item_entry.contributable_type, item.id) + '/download'){'click here to download this pack separately'}} ]") : "") + "<br/>" +
              uploader_string(item.contributor_type, item.contributor_id, true) + "<br/>"
            end +
            pack_metadata
          end
        }
      
      when "text"
        pack_data += "- Pack: #{item.title}"
        pack_data += "\n  Location: " + location_string(item_entry.contributable_type, item.id)
        if download_allowed
          pack_data += "\n  Download link: " + location_string(item_entry.contributable_type, item.id) + "/download ( --download of nested packs is not supported, however using this link it can be downloaded separately-- )"
        end
        pack_data += "\n  " + uploader_string(item.contributor_type, item.contributor_id, false) + "\n"
        pack_data += pack_metadata
      
      else
        return "ERROR"
    end
    
    return pack_data
  end
  
  
  # for external pack items (i.e. links that are external to myExperiment) 
  def generate_external_item_data(format, cgi, item_entry)
    item_data = ""
    item_metadata = generate_item_metadata(format, cgi, item_entry)
    
    case format.downcase
      when "html"
        item_data += cgi.li("class" => "link"){
          cgi.div("class" => "external_item") do
            cgi.div("class" => "item_data") do
              "#{item_entry.title} - " + cgi.a(item_entry.uri){item_entry.uri} +
              "<br/>Alternate link: " + (item_entry.alternate_uri.nil? || item_entry.alternate_uri.blank? ? "<span class='none_text'>none</span>" : cgi.a(item_entry.alternate_uri){item_entry.alternate_uri}) + "<br/>"
            end +
            item_metadata
          end
        }
      
      when "text"
        item_data += "+ #{item_entry.title} - #{item_entry.uri}\n"
        item_data += "  (alternate link: #{item_entry.alternate_uri.nil? || item_entry.alternate_uri.blank? ? "none" : item_entry.alternate_uri})\n"
        item_data += item_metadata
      
      else
        return "ERROR"
    end
  
    return item_data
  end
  
  
  # for pack items that don't have neither download, nor view permissions
  def generate_hidden_item_data(format, cgi, item_entry, item_doesnt_exist=false)
    item_data = ""
    
    case format.downcase
      when "html"
        item_data += cgi.li("class" => "denied"){
          cgi.div("class" => "hidden_item") do
            cgi.div("class" => "item_data") do
              (item_doesnt_exist ?
               "<b>The item this entry points to is not available. It may have been deleted.</b>" :
               "<b>You don't have permissions to view this item</b><br/>"
              )
            end +
            cgi.div("class" => "item_metadata") do
              "Added to pack by: " + uploader_string("user", item_entry.user_id, true, false) + " (#{item_entry.created_at.strftime('%d/%m/%Y @ %H:%M:%S')})<br/>"
            end
          end
        }
        
      when "text"
        item_data += (item_doesnt_exist ? 
                      "- The item this entry points to is not available. It may have been deleted.\n" :
                      "- You don't have permissions to view this item\n"
                     )
        item_data += "  | Added to pack by: " + uploader_string("user", item_entry.user_id, false, false) + "; added on (#{item_entry.created_at.strftime('%d/%m/%Y @ %H:%M:%S')})"
      
      else
        return "ERROR"
        
    end
    
    return item_data
  end
  
  def rank

    boost = 0

    # initial boost depends on viewings count
    boost = contribution.viewings_count / 100 if contribution

    # Take curation events into account
    boost += CurationEvent.curation_score(CurationEvent.find_all_by_object_type_and_object_id('Pack', id))
    
    # penalty for no description
    boost -= 20 if description.nil? || description.empty?
    
    boost
  end

  def create_research_object

    slug = "Pack#{self.id}"
    slug = SecureRandom.uuid if ResearchObject.find_by_slug_and_version(slug, nil)

    ro = build_research_object(:slug => slug, :user => self.contributor)
    ro.save
  end
end
