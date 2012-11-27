module ROSRS

  # A representation of a folder in a Research Object.
  class Folder < Resource

    attr_reader :name

    ##
    # +research_object+:: The Wf4Ever::ResearchObject that aggregates this folder.
    # +uri+::             The URI for the resource referred to by the Folder.
    # +options+::         A hash of options:
    # [:contents_graph]   An RDFGraph of the folder contents, if on hand (to save having to make a request).
    # [:root_folder]      A boolean flag to say if this folder is the root folder of the RO.
    def initialize(research_object, uri, proxy_uri = nil, options = {})
      super(research_object, uri, proxy_uri)
      @name = uri.to_s.split('/').last
      @session = research_object.session
      @loaded = false
      if options[:contents_graph]
        @contents = parse_folder_description(options[:contents_graph])
        @loaded = true
      end
      @root_folder = options[:root_folder]
    end

    ##
    # Fetch the entry with name +child_name+ from the Folder's contents
    def child(child_name)
      contents.select {|child| child.name == child_name}.first
    end

    ##
    # Returns boolean stating whether or not a description of this Folder's contents has been fetched and loaded.
    def loaded?
      @loaded
    end

    ##
    # Returns whether or not this folder is the root folder of the RO
    def root?
      @root_folder
    end

    ##
    # Returns an array of FolderEntry objects
    def contents
      load unless loaded?
      @contents
    end

    ##
    # Fetch and parse the Folder's description to get the Folder's contents.
    def load
      @contents = fetch_folder_contents
      @loaded = true
    end

    ##
    # Delete this folder from the RO. Contents will be preserved.
    # Also deletes any entries in other folders pointing to this one.
    def delete
      code = @session.delete_folder(@uri)[0]
      @loaded = false
      @research_object.remove_folder(self)
      code == 204
    end

    ##
    # Add an entry to the folder. +resource+ can be a ROSRS::Resource object or a URI
    def add(resource, entry_name = nil)
      if resource.instance_of?(ROSRS::Resource)
        contents << ROSRS::FolderEntry.create(self, entry_name, resource.uri)
      else
        contents << ROSRS::FolderEntry.create(self, entry_name, resource)
      end

    end

    ##
    # Remove an entry from the folder.
    def remove(entry)
      entry.delete
      contents.delete(entry)
    end

    ##
    # Create a folder in the RO and add it to this folder as a subfolder
    def create_folder(name)
      # Makes folder name parent/child instead of just child
      folder_name = (URI(uri) + URI(name) - URI(@research_object.uri)).to_s
      folder = @research_object.create_folder(folder_name)
      add(folder.uri, name)
      folder
    end

    def self.create(ro, name, contents = [])
      code, reason, uri, proxy_uri, folder_description = ro.session.create_folder(ro.uri, name, contents)
      self.new(ro, uri, proxy_uri, :contents_graph => folder_description)
    end

    private

    # Get folder contents from remote resource map file
    def fetch_folder_contents
      code, reason, headers, uripath, graph = @session.get_folder(uri)
      parse_folder_description(graph)
    end

    def parse_folder_description(graph)
      contents = []

      query = RDF::Query.new do
        pattern [:folder_entry, RDF.type, RDF::RO.FolderEntry]
        pattern [:folder_entry, RDF::RO.entryName, :name]
        pattern [:folder_entry, RDF::ORE.proxyFor, :target]
      end

      # Create instances for each item.
      graph.query(query).each do |result|
        contents << ROSRS::FolderEntry.new(self, result.name.to_s, result.folder_entry.to_s, result.target.to_s)
      end

      contents
    end

  end
end