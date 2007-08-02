class MockFile
  attr_reader :path
	def initialize(path)
		@path = path
	end
	
	def size
  	1
  end
  
  def read
    File.open(@path) { |f| f.read }
  end
end