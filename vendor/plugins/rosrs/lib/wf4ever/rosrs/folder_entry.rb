module ROSRS

  # An item within a folder.

  class FolderEntry

    attr_reader :parent_folder, :name, :uri

    ##
    # +parent_folder+:: The ROSRS::Folder object in which this entry resides..
    # +name+::          The display name of the ROSRS::FolderEntry.
    # +uri+::           The URI of this ROSRS::FolderEntry
    # +resource_uri+::  The URI for the resource referred to by this ROSRS::FolderEntry.
    def initialize(parent_folder, name, uri, resource_uri)
      @uri = uri
      @name = name
      @resource_uri = resource_uri
      @parent_folder = parent_folder
      @session = @parent_folder.research_object.session
    end

    # The resource that this entry points to. Lazily loaded.
    def resource
      @resource ||= @parent_folder.research_object.resources(@resource_uri) ||
                    @parent_folder.research_object.folders(@resource_uri) ||
                    ROSRS::Resource.new(@parent_folder.research_object, @resource_uri)
    end

    ##
    # Removes this folder entry from the folder. Does not delete the resource.
    def delete
      code = @session.delete_resource(@uri)[0]
      @loaded = false
      code == 204
    end

    def self.create(parent_folder, name, resource_uri)
      code, reason, uri = parent_folder.research_object.session.add_folder_entry(parent_folder.uri, resource_uri, name)
      self.new(parent_folder, name, uri, resource_uri)
    end

  end

end