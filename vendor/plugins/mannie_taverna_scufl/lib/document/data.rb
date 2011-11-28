module Document # :nodoc:
	
	#Input or output data
	#
	#value - the data value or a (possibly nested) list of data values
	class Data
		attr_accessor :value, :annotation
		
		def initialize(value=nil, annotation=nil)
			@value = value
			@annotation = annotation
		end
				
		def eql?(other)
			@value.eql?(other.value) and @annotation.eql?(other.annotation)
		end
		
		def ==(other)
			@value == other.value and @annotation == other.annotation
		end
		
	end
	
end