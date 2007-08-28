module FlexImage
  class View
    class TemplateDidNotReturnImage < RuntimeError #:nodoc:
    end
    
    def initialize(view)
      @view = view
    end
    
    def render(template, local_assigns = {})
        
      # process the view
      result = @view.instance_eval do
        
        # inject assigns into instance variables
        assigns.each do |key, value|
          instance_variable_set "@#{key}", value
        end
        
        # inject local assigns into reader methods
        local_assigns.each do |key, value|
          class << self; self; end.send(:define_method, key) { val }
        end
        
        #execute the template
        eval(template)
      end
      
      # convert result to jpg
      result.to_jpg!
      
      # Set proper content type
      @view.controller.headers["Content-Type"] = 'image/jpg'
      
      # Raise an error if object returned from template is not an image record
      unless result.is_a?(FlexImage::Model)
        raise TemplateDidNotReturnImage, ".flexi template was expected to return a <FlexImage::Model> object, but got a <#{result.class}> instead."
      end
      
      # Return image data
      result[result.class.binary_column]
    ensure
    
      # ensure garbage collection happens after every flex image render
      GC.start
    end
  end
end