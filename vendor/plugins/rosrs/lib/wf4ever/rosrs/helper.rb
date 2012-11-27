module ROSRS
  module Helper
    def self.is_uri?(object)
      if object.is_a?(URI) ||
         object.is_a?(String) && (object.start_with?("/") || object.start_with?("http"))
        true
      else
        false
      end
    end
  end
end