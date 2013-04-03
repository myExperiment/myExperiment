# myExperiment: config/initializers/stringio_patch.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

if RUBY_VERSION < "1.9.1"
  class StringIO
    def readpartial(*args)
      result = read(*args)
      if result.nil?
        raise EOFError
      else
        result
      end
    end
  end
end

