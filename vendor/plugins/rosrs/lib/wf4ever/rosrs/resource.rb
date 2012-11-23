module ROSRS

  class Resource
    attr_reader :uri, :proxy_uri

    def initialize(research_object, uri, proxy_uri, external = false)
      @research_object = research_object
      @uri = uri
      @proxy_uri = proxy_uri
      @session = @research_object.session
      @external = external
    end

    ##
    # Removes this resource from the Research Object.
    def delete!
      if internal?
        @session.remove_resource(@uri)
      elsif external?
        @session.remove_resource(@proxy_uri)
      end
      true
    end

    def internal?
      !external
    end

    def external?
      external
    end

  end
end