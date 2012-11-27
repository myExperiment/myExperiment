module ROSRS
  class Annotation

    attr_reader :uri, :body_uri, :resource_uri, :created_at, :created_by, :research_object

    def initialize(research_object, uri, body_uri, resource_uri, options = {})
      @research_object = research_object
      @session = @research_object.session
      @uri = uri
      @body_uri = body_uri
      @resource_uri = resource_uri
      @created_at = options[:created_at]
      @created_by = options[:created_by]
      @loaded = false
      if options[:body]
        @body = options[:body]
        @loaded = true
      end
      load if options[:load]
    end

    ##
    # The resource which this annotation relates to
    def resource
      @resource ||= @research_object.resources(@resource_uri) ||
                    @research_object.folders(@resource_uri) ||
                    ROSRS::Resource.new(@research_object, @resource_uri)
    end

    def loaded?
      @loaded
    end

    def load
      c,r,u,@body = @session.get_annotation(body_uri)
      @loaded = true
    end

    def body
      load unless loaded?
      @body
    end

    def delete
      code = @session.remove_annotation(uri)
      @loaded = false
      @research_object.remove_annotation(self)
      code == 204
    end

    def self.create(ro, resource_uri, annotation)
      if ROSRS::Helper.is_uri?(annotation)
        code, reason, annotation_uri = ro.session.create_annotation_stub(ro.uri, resource_uri, annotation)
        self.new(ro, annotation_uri, annotation, resource_uri)
      else
        code, reason, annotation_uri, body_uri = ro.session.create_internal_annotation(ro.uri, resource_uri, annotation)
        self.new(ro, annotation_uri, body_uri, resource_uri, :body => annotation)
      end
    end

    def update(resource_uri, annotation)
      if ROSRS::Helper.is_uri?(annotation)
        code, reason = @session.update_annotation_stub(@research_object.uri, @uri, resource_uri, body_uri)
        @loaded = false
      else
        code, reason, body_uri = @session.update_internal_annotation(@research_object.uri, @uri, resource_uri, annotation)
        @loaded = true
        @body = annotation
      end
      @resource_uri = resource_uri
      @body_uri = body_uri
      self
    end

  end
end