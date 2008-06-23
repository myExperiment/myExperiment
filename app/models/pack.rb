# myExperiment: app/models/pack.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'
require 'uri'

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
            type, id = arr[0][0], arr[0][1]
            
            # Try to find the contributable item being pointed at
            case type.downcase
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
  
end
