module Document
  
	class Report
  
		attr_reader :processors
		attr_accessor :id, :status
		
		def initialize
		  	@processors = Array.new
		end
		
		def self.from_xml(xml)
			Reader.read(xml)  
		end
	  
		def self.from_document(document)
			Reader.read(document)  
		end
	  
	end
	
	class Processor
		attr_accessor :name, :status, :time, :total, :number 
	end
    
	class Reader

		def self.read(report)
			if report.kind_of?(REXML::Document)
				document = report
			else
				document = REXML::Document.new(report)
			end
			root = document.root
					  
			return nil if not root
								  
			raise root.name + "Doesn't appear to be a workflow report!" if root.name != "workflowReport"
								  
			create_report(root)
		end
	  
		def self.create_report(element)
			report = Report.new
			
			id = element.attribute('workflowId')
			report.id = id.value if id
			
			status = element.attribute('workflowStatus')
			report.status = status.value if status
			
			element.elements['processorList'].each_element('processor') { |processor|
			  add_processor(processor, report)
			}
			
			report
		end
	  
		def self.add_processor(element, report)
			processor = Processor.new
			
			name = element.attribute('name')
			processor.name = name.value if name
				
			if element.has_elements?
			  	firstElement = element.elements[1]
				case firstElement.name
				when 'ProcessComplete'
			   		processor.status = 'COMPLETE'
					processor.time = firstElement.attribute('TimeStamp')
				when 'ProcessScheduled'
			   		processor.status = 'SCHEDULED'
					processor.time = firstElement.attribute('TimeStamp')
				when 'InvokingWithIteration'
					processor.status = 'ITERATING'
					processor.time = firstElement.attribute('TimeStamp')
					processor.number = firstElement.attribute('IterationNumber')
					processor.total = firstElement.attribute('IterationTotal')			 
				when 'ServiceFailure'
					processor.status = 'FAILED'
					processor.time = firstElement.attribute('TimeStamp')
				else
					processor.status = 'UNKNOWN'
				end
			end
			report.processors.push processor		
		end
	  	
	end
	
end
