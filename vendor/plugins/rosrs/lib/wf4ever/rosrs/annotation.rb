module ROSRS
  class Annotation

    attr_reader :uri, :body_uri, :resource_uri, :created_at, :created_by, :research_object

    def initialize(research_object, uri, body_uri, resource_uri, created_at = nil, created_by = nil, options = {})
      @research_object = research_object
      @session = @research_object.session
      @uri = uri
      @body_uri = body_uri
      @resource_uri = resource_uri
      @created_at = created_at
      @created_by = created_by
      @loaded = false
      if options[:body]
        @body = options[:body]
        @loaded = true
      end
      load! if options[:load]
    end

    def loaded?
      @loaded
    end

    def load!
      @body = @session.get_annotation(body_uri || uri)
      @loaded = true
    end

    def body
      load! unless loaded?
      @body
    end

    def delete!
      @session.remove_annotation(uri)
      true
    end

    def self.create(ro, resource_uri, annotation_graph)
      code, reason, annotation_uri, body_uri = ro.session.create_internal_annotation(ro.uri, resource_uri, annotation_graph)
      self.new(ro, annotation_uri, body_uri, resource_uri, :body => annotation_graph)
    end

    def self.create_remote(ro, resource_uri, body_uri)
      code, reason, annotation_uri = ro.session.create_annotation_stub(ro.uri, resource_uri, body_uri)
      self.new(ro, annotation_uri, body_uri, resource_uri)
    end

    def update!(resource_uri, annotation_graph)
      code, reason, body_uri = @session.update_internal_annotation(@research_object.uri, @uri, resource_uri, annotation_graph)
      @resource_uri = resource_uri
      @body_uri = body_uri
      @body = annotation_graph
      @loaded = true
      self
    end

    def update_remote!(resource_uri, body_uri)
      code, reason = @session.update_annotation_stub(@research_object.uri, @uri, resource_uri, body_uri)
      @resource_uri = resource_uri
      @body_uri = body_uri
      @loaded = false
      self
    end

  end
end