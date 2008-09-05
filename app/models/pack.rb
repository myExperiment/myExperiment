# myExperiment: app/models/pack.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'
require 'uri'
require 'zip/zip'
require 'tempfile'
require 'cgi'


class Pack < ActiveRecord::Base
  acts_as_contributable
  
  validates_presence_of :title
  
  format_attribute :description
  
  acts_as_solr(:fields => [ :title, :description, :contributor_name, :tag_list ],
               :include => [ :comments ]) if SOLR_ENABLE
  
  has_many :contributable_entries,
           :class_name => "PackContributableEntry",
           :foreign_key => :pack_id,
           :order => "created_at DESC",
           :dependent => :destroy
  
  has_many :remote_entries,
           :class_name => "PackRemoteEntry",
           :foreign_key => :pack_id,
           :order => "created_at DESC",
           :dependent => :destroy
  
  def items_count
    return contributable_entries_count + remote_entries_count
  end
  
  
  def self.archive_folder
    # single declaration point of where the zip archives for downloadable packs would live
    #return "tmp/packs/" # -> TODO: grant write permission into this folder
    return "" # root is used for now
  end
  
  def archive_file
    # the name of the zip file, where contents of current pack will be placed
    "pack_#{id}.zip"
  end
  
  def archive_file_path
    # "#{BASE_URI}/packs/#{id}/download/pack_#{id}.zip"
    return( Pack.archive_folder + archive_file )
  end
  
  
  def create_zip(user)
    # ========= PACK DESCRIPTION ===========
    #
    # plain-TEXT
    # generate pack description data (which will be put into a text file in the archive)
    pack_data = "****** Snapshot of the Pack: #{self.title} ******\n\n"
    pack_data += "Downloaded from myExperiment.org\n"
    pack_data += "Snapshot generated on " + Time.now.strftime("%H:%M:%S on %A, %d %B %Y") + "\n\n\n\n"
    pack_data += "======= Pack Details =======\n\n"
    pack_data += "Title: #{self.title}"
    pack_data += "\nLocation: #{location_string("pack", self.id)}"
    pack_data += "\nCreated by: " + uploader_string(self.contributor_type, self.contributor_id, false, false)
    pack_data += "\nCreated at: " + self.created_at.strftime("%H:%M:%S on %A, %d %B %Y")
    pack_data += "\nLast updated at: " + self.updated_at.strftime("%H:%M:%S on %A, %d %B %Y")
    pack_data += "\n\nDescription: " + (self.description.nil? || self.description.empty? ? "none" : "\n\n" + strip_html(self.description) )
    #
    # HTML
    cgi = CGI.new("html3")
    html_details = cgi.div("class" => "pack_metadata") do
      cgi.div("class" => "pack_details") do
        cgi.h2 {"Pack Details"} +
        cgi.table() {
          cgi.tr() { cgi.td{"Title"} + cgi.td{cgi.a(location_string("pack", self.id)){self.title}} } +
          cgi.tr() { cgi.td{"Created by"} + cgi.td{uploader_string(self.contributor_type, self.contributor_id, true, false)} } +
          cgi.tr() { cgi.td{"Created at"} + cgi.td{self.created_at.strftime("%H:%M:%S on %A, %d %B %Y")} } +
          cgi.tr() { cgi.td{"Last updated at"} + cgi.td{self.updated_at.strftime("%H:%M:%S on %A, %d %B %Y")} }
        }
      end +
      cgi.div("class" => "pack_description") do
        cgi.h2 {"Description"} +
        cgi.p { (self.description.nil? || self.description.empty? ? "none" : self.description ) }
      end
    end
    
    
    # ========= CREATE THE ZIP FILE & WRITE ALL PACK ENTRIES INTO IT ===========
    # (also collect metadata about all the entries in plain text and HTML formats)
    
    # check to see if the file exists already, and if it does, delete it
    archive_filename = self.archive_file
    if File.file?(archive_filename)
      File.delete(archive_filename)
    end 

    # create the zip file
    zipfile = Zip::ZipFile.open(archive_file_path, Zip::ZipFile::CREATE)
    
      # will keep a list of all filenames that are put into the archive (to delete temp files later)
      zip_filenames = []
           
      # now add all pack items to the zip archive
      item = nil
      # start with internal items
      counter_internal = 0
      pack_items_internal = ""
      html_items_internal = ""
      self.contributable_entries.each { |item_entry|
        counter_internal += 1
        
        # the first thing to do with each item is to check if download is allowed
        item_contribution = Contribution.find( :first, :conditions => ["contributable_type = ? AND contributable_id = ?", item_entry.contributable_type, item_entry.contributable_id])
        download_allowed = item_contribution.authorized? ("download", user)
        viewing_allowed = download_allowed ? true : item_contribution.authorized? ("view", user)
        
        
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
              zipfile.get_output_stream( required_item_version.unique_name + ".xml" ) { |stream| stream.write(required_item_version.content_blob.data)}
              zip_filenames << required_item_version.unique_name + ".xml" 
            
              # add metadata about the workflow to HTML and textual summary
              pack_items_internal += "+ Workflow: #{required_item_version.title} (local copy: #{required_item_version.unique_name + ".xml"})\n"
              pack_items_internal += "  Location: " + location_string(item_entry.contributable_type, required_item_version.id, wf_version) + "\n"
              pack_items_internal += "  Version: #{wf_version} (created on: #{required_item_version.created_at.strftime("%d/%m/%Y")}, last updated on: #{required_item_version.updated_at.strftime("%d/%m/%Y")})\n"
              pack_items_internal += "  " + uploader_string(required_item_version.contributor_type, required_item_version.contributor_id, false) + "\n"
              pack_items_internal += "  Added to pack by: " + uploader_string("user", item_entry.user_id, false, false) + "\n"
              
              html_items_internal += cgi.li{
                cgi.div("class" => "workflow_item") do
                  cgi.div("class" => "item_data") do
                    "<b>Workflow: </b>" + cgi.a(location_string(item_entry.contributable_type, item.id, wf_version)){required_item_version.title} + "&nbsp;&nbsp;&nbsp;[ " + cgi.a("./" + required_item_version.unique_name + ".xml"){"open local copy"} + " ]<br/>" +
                    "Version: #{wf_version} (created on: #{required_item_version.created_at.strftime("%d/%m/%Y")}, last updated on: #{required_item_version.updated_at.strftime("%d/%m/%Y")})<br/>" +
                    uploader_string(required_item_version.contributor_type, required_item_version.contributor_id, true) + "<br/>"
                  end +
                  cgi.div("class" => "item_metadata") do
                    "Added to pack by: " + uploader_string("user", item_entry.user_id, true, false) + "<br/>" +
                    item_comment_string(item_entry, true)
                  end 
                end
              } 
            # ELSE - version was not found; display error  
            else
              pack_items_internal += "+ Workflow: #{item.title} ( !! VERSION NOT FOUND !!)\n"
              pack_items_internal += "  Version: #{wf_version}\n"
              
              html_items_internal += cgi.li{ 
                cgi.div("class" => "workflow_item") do
                  cgi.div("class" => "item_data") do
                    "<b>Workflow: </b>" + item.title + " (<font style='color: red;'> !! VERSION NOT FOUND !! </font>)<br/>" +
                    "Version: #{wf_version}"
                  end
                end
              }
            end

          when "blob"
            item = Blob.find(item_entry.contributable_id)
            zipfile.get_output_stream( item.local_name ) { |stream| stream.write(ContentBlob.find(item.content_blob_id).data) }
            zip_filenames << item.local_name
            
            pack_items_internal += "+ File: #{item.title} (#{item.local_name})\n"
            pack_items_internal += "  Location: " + location_string(item_entry.contributable_type, item.id) + "\n"
            pack_items_internal += "  " + uploader_string(item.contributor_type, item.contributor_id, false) + "\n"
            pack_items_internal += "  Added to pack by: " + uploader_string("user", item_entry.user_id, false, false) + "\n"
            
            
            html_items_internal += cgi.li{ 
              cgi.div("class" => "file_item") do
                cgi.div("class" => "item_data") do
                  "<b>File: </b>" + cgi.a(location_string(item_entry.contributable_type, item.id)){item.title} + "&nbsp;&nbsp;&nbsp;[ " + cgi.a("./" + item.local_name){"open local copy"} + " ]<br/>" +
                  uploader_string(item.contributor_type, item.contributor_id, true) + "<br/>"
                end +
                cgi.div("class" => "item_metadata") do
                  "Added to pack by: " + uploader_string("user", item_entry.user_id, true, false) + "<br/>" +
                  item_comment_string(item_entry, true)
                end
              end
            }
          when "pack"
            item = Pack.find(item_entry.contributable_id)
            
            pack_items_internal += "- Pack: #{item.title} ( --download of nested packs is not supported-- )\n"
            pack_items_internal += "  Location: " + location_string(item_entry.contributable_type, item.id) + "\n"
            pack_items_internal += "  " + uploader_string(item.contributor_type, item.contributor_id, false) + "\n"
            pack_items_internal += "  Added to pack by: " + uploader_string("user", item_entry.user_id, false, false) + "\n"
            
            html_items_internal += cgi.li {
              cgi.div("class" => "pack_item") do
                cgi.div("class" => "item_data") do
                  "<b>Pack: </b>" + cgi.a(location_string(item_entry.contributable_type, item.id)){item.title} + "&nbsp;&nbsp;&nbsp;[ <i>download of nested packs is not supported</i> ]<br/>" +
                  uploader_string(item.contributor_type, item.contributor_id, true) + "<br/>"
                end +
                cgi.div("class" => "item_metadata") do
                  "Added to pack by: " + uploader_string("user", item_entry.user_id, true, false) + "<br/>" +
                  item_comment_string(item_entry, true)
                end
              end
            }
        end
        
        pack_items_internal += "  " + item_comment_string(item_entry, false) + "\n\n"
      }
      pack_items_internal = "\n\n\n======= Internal items (#{counter_internal}) ========\n\n" + pack_items_internal
      html_items_internal = cgi.div("class" => "pack_items_internal") do
        cgi.h3{"Internal items (#{counter_internal})"} +
        cgi.ul {
          html_items_internal
        }
      end
      
      # continue with external items      
      counter_external = 0
      pack_items_external = ""
      html_items_external = ""
      self.remote_entries.each { |item|
        counter_external += 1
        pack_items_external += "+ #{item.title} - #{item.uri}\n  (alternate link: #{item.alternate_uri.nil? || item.alternate_uri.blank? ? "none" : item.alternate_uri})\n  Added to pack by: #{uploader_string("user", item.user_id, false, false)}\n  #{item_comment_string(item, false)}\n\n"
        html_items_external += cgi.li {
          cgi.div("class" => "external_item") do
            cgi.div("class" => "item_data") do
              "#{item.title} - " + cgi.a(item.uri){item.uri} +
              "<br/>Alternate link: " + (item.alternate_uri.nil? || item.alternate_uri.blank? ? "<i>none</i>" : cgi.a(item.alternate_uri){item.alternate_uri}) + "<br/>"
            end +
            cgi.div("class" => "item_metadata") do
              "Added to pack by: " + uploader_string("user", item.user_id, true, false) + "<br/>" +
              item_comment_string(item, true)
            end
          end
        }
      }
      pack_items_external = "\n\n======= External items (#{counter_external}) =======\n\n" + pack_items_external
      html_items_external = cgi.div("class" => "pack_items_external") do
        cgi.h3{"External items (#{counter_external})"} +
        cgi.ul {
          html_items_external
        }
      end
      
      
      # ASSEMBLE ALL PARTS OF TEXT AND HTML DESCRIPTION FILES
      #
      # TEXT
      #
      # assemble pack data & item data together; also add date & 'downloaded from'
      pack_data += "\n\n\n\n======= Items (#{(counter_internal + counter_external).to_s}) =======\n\n"
      pack_data += "Total number of items in the pack: " + (counter_internal + counter_external).to_s + "\n"
      pack_data += "Internal items: #{counter_internal}\n"
      pack_data += "External items: #{counter_external}\n"
      pack_data += pack_items_internal + pack_items_external
      #
      # HTML
      html_data = cgi.html{
        cgi.head{ 
          cgi.title{"Snapshot of the Pack: #{self.title} (from myExperiment.org)"} +
          cgi.link("href" => "index.css", "media" => "screen", "rel" => "Stylesheet", "type" => "text/css")
        } +
        cgi.body{
          cgi.h1{"Snapshot of the Pack: #{self.title}"} +
          cgi.div("class" => "provider_info") do
            cgi.p{
              cgi.i{"Downloaded from #{cgi.a(BASE_URI){'myExperiment.org'}} website<br/>" +
              "Snapshot generated on " + Time.now.strftime("%H:%M:%S on %A, %d %B %Y")} 
            }
          end +
          html_details +
          cgi.div("class" => "pack_items") do
            cgi.h2{"Items (#{counter_internal + counter_external})"} +
            html_items_internal +
            html_items_external
          end
        }
      }
      
      # STORE DESCRIPTION DATA IN RELEVANT FILES
      #
      # TEXT
      # put pack data into temporary file & add it to archive; then delete
      info = Tempfile.new("pack_#{self.id}.tmp")
      info.write(pack_data)
      info.close()
      zipfile.add( "_Pack Info.txt", info.path )
      #
      # HTML
      index = Tempfile.new("index.html.tmp")
      index.write( CGI::pretty(html_data) )
      index.close()
      zipfile.add( "index.html", index.path )
      #
      # CSS
      zipfile.add( "index.css", "./public/stylesheets/pack-snapshot.css")
   
   # finalize the archive file
   zipfile.close()

   # set read permissions on the zip file
   File.chmod(0644, archive_filename)
   
   # remove any temporary files that were created while creating the zip file
   zip_filenames.each do |temp_file|
     FileUtils.rm Dir.glob("#{temp_file}.*"), :force => true # 'force' option makes sure that exceptions are never raised
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
      
      if uri.absolute?
        if is_internal_uri?(uri, host_name, host_port)
          # Attempt to initialise a pack_contributable_entry
          
          expr = /^\/(workflows|files|packs)\/(\d+)$/   # e.g: "\workflows\45"
          if uri.path =~ expr
            arr = uri.path.scan(expr)
            c_type, id = arr[0][0], arr[0][1]
            
            # Try to find the contributable item being pointed at
            case c_type.downcase
            when 'workflows'
              contributable = Workflow.find(:first, :conditions => ["id = ?", id])
            when 'files'
              contributable = Blob.find(:first, :conditions => ["id = ?", id])
            when 'packs'
              contributable = Pack.find(:first, :conditions => ["id = ?", id])
            else
              contributable = nil
            end
            
            if contributable
              entry = PackContributableEntry.new
              entry.contributable = contributable
              
              type = 'contributable'
              
              # check if the 'contributable' is a pack, then that it's not the same pack,
              # to which we are trying to add something at the moment
              if c_type.downcase == 'packs' && contributable.id == self.id
                errors_here.add_to_base('Cannot add the pack to itself')
              end
              
              # Check if version was specified in the uri
              unless uri.query.blank?
                expr2 = /version=(\d+)/
                if uri.query =~ expr2
                  entry.contributable_version = uri.query.scan(expr2)[0][0] 
                end
              end
            else
              errors_here.add_to_base('The item the link points to does not exist.')
            end
          else
            # Treat as a remote entry
            is_remote = true
          end
          
        else
          # Treat as a remote entry
          is_remote = true
        end
      else
        errors_here.add_to_base('Please provide a valid link.')  
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
      errors_here.add_to_base('Really struggled to parse this link. Please could you check if it is valid.')
    end
    
    return [errors_here, type, entry]
  end
  
  protected
  
  # Checks if the uri provided points to something internally to the host site. 
  # Note: assumes that the host site runs on HTTP.
  def is_internal_uri?(uri, host_name, host_port)
    return ((uri.scheme == "http") && (uri.host == host_name) && (uri.port.to_s == host_port)) 
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
          res += "<a href=#{BASE_URI}/users/#{contributor_id}>#{user.name}</a>"
        else
          res += user.name + " (profile: #{BASE_URI}/users/#{contributor_id})"
        end
      when "network"
        group = Network.find(contributor_id)
        if html_required
          res += "<a href=#{BASE_URI}/groups/#{contributor_id}>\"#{group.title}\" group</a>"
        else
          res += group.title + " (profile: #{BASE_URI}/groups/#{contributor_id})"
        end
      else
        res += "unknown (contributor_type: #{contributor_type}; contributor_id: #{contributor_id})"
    end
    
    return res
  end
  
  # a helper to return the link to a resource based on type, id & version 
  # (version is NIL by default - means no version, or the latest one)
  def location_string(type, id, version=nil)
    link = BASE_URI
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
    
    return( "Comment: #{html_required ? '<i>' : ''}#{item.comment.nil? || item.comment.blank? ? 'none' : item.comment}#{html_required ? '</i>' : ''}" )
  end
  
  # strips off html tags from a string and returns the 'clean' result
  # (used for textual - non-HTML - representation of descriptions, etc)
  def strip_html( str )
    # TODO: don't strip <br> tags -> instead replace them with "\n"
    return str.gsub(/<\/?[^>]*>/,  "")
  end
  
end
