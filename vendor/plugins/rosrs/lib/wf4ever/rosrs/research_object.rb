module ROSRS

  class ResearchObject

    attr_reader :uri, :session

    def initialize(rosrs_session, uri)
      @session = rosrs_session
      @uri = uri
      @loaded = false
    end

    def loaded?
      @loaded
    end

    def load!
      manifest_uri, @manifest = @session.get_manifest(uri)
      @annotations = extract_annotations
      @root_folder = extract_root_folder
      @loaded = true
    end

    def manifest
      load! unless loaded?
      @manifest
    end

    def annotations(resource_uri = nil)
      load! unless loaded?
      if resource_uri.nil?
        @annotations
      else
        @annotations.select {|a| a.resource_uri == resource_uri}
      end
    end

    def root_folder
      load! unless loaded?
      @root_folder
    end

    def delete!
      @session.delete_research_object(uri)
      true
    end

    ##
    # Create an annotation for a given resource_uri, using the supplied annotation body.
    def create_annotation(resource_uri, annotation_body)
      annotation = ROSRS::Annotation.create(self, resource_uri, annotation_body)
      annotations << annotation
      annotation
    end

    ##
    # Create an annotation for a given resource_uri, using a remote body pointed to by body_uri.
    def create_remote_annotation(resource_uri, body_uri)
      annotation = ROSRS::Annotation.create_remote(self, resource_uri, body_uri)
      annotations << annotation
      annotation
    end

    ##
    # Create a root folder in the research object if one doesn't already exist.
    def create_folder(name)
      @session.create_folder(@uri, name)
    end

    private

    def extract_annotations
      annotations = []
      queries = [RDF::RO.annotatesAggregatedResource, RDF::AO.annotatesResource].collect do |predicate|
        RDF::Query.new do
          pattern [:annotation_uri, RDF.type, RDF::RO.AggregatedAnnotation]
          pattern [:annotation_uri, predicate, :resource_uri]
          pattern [:annotation_uri, RDF::AO.body, :body_uri]
          pattern [:annotation_uri, RDF::DC.creator, :created_by]
          pattern [:annotation_uri, RDF::DC.created, :created_at]
        end
      end

      queries.each do |query|
        @manifest.query(query) do |result|
            annotations << ROSRS::Annotation.new(self,
                                                   result.annotation_uri.to_s,
                                                   result.body_uri.to_s,
                                                   result.resource_uri.to_s,
                                                   result.created_at.to_s,
                                                   result.created_by.to_s)
        end
      end

      annotations
    end

    def extract_root_folder
      query = RDF::Query.new do
        pattern [:research_object, RDF::RO.rootFolder,  :folder]
        pattern [:folder, RDF::ORE.isDescribedBy, :folder_resource_map]
      end

      result = @manifest.query(query).first
      if result
        folder_uri = result.folder.to_s
        folder_name = folder_uri.to_s.split('/').last
        ROSRS::Folder.new(self, folder_name, folder_uri)
      else
        nil
      end
    end

  end
end