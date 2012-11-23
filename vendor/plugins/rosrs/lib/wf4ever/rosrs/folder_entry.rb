module ROSRS

  # An item within a folder.

  class FolderEntry < Resource

    attr_reader :parent_folder, :name, :uri, :resource_uri

    ##
    # +parent_folder+:: The ROSRS::Folder object in which this entry resides..
    # +name+::          The display name of the ROSRS::FolderEntry.
    # +uri+::           The URI of this ROSRS::FolderEntry
    # +resource_uri+::  The URI for the resource referred to by this ROSRS::FolderEntry.
    # +folder+::        (Optional) The ROSRS::Folder that this entry points to, if applicable.
    def initialize(parent_folder, name, uri, resource_uri, folder = nil)
      super(folder.research_object, uri, resource_uri)
      @name = name
      @folder = folder
      @is_folder = !options[:folder].nil?
      @resource = options[:folder]
      @session = @folder.research_object.session
    end

    ##
    # Returns boolean stating whether or not this entry points to a folder
    def folder?
      @is_folder
    end

  end

end