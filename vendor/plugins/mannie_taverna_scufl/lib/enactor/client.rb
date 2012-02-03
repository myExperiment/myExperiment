require 'rubygems'
require 'builder'
require "uri"
require 'rexml/document'
require 'net/http'
require 'baclava/reader'
require 'baclava/writer'
require 'document/report'
require 'document/data'

module Enactor # :nodoc:

	#Base class for Taverna service errors.
	class TavernaServiceError < StandardError
	end

	#Job did not complete. 
    #Thrown by execute_sync()
	class NotCompleteError < TavernaServiceError
		def initialize(job_url, status)
			super("Job #{job_url} not complete, status: #{status}")
    	end
	end

	#Could not create resource.
	class CouldNotCreateError < TavernaServiceError
    	def initialize(url)
        	super("Expected 201 Created when uploading #url")
    	end
	end
	
	
    #Status messages that can be returned from TavernaService.get_job_status().
    #
    #If finished?(status) is true, this means the job is finished, 
    #either successfully (COMPLETE), unsuccessfully (CANCELLED, FAILED), or 
    #that the job is no longer in the database (DESTROYED).
    #
    #When a job has just been created it will be in status NEW, after that 
    #it will immediately be on a queue and in the state QUEUED. Once the 
    #job has been picked up by a worker it will be in INITIALISING, this 
    #state might include the startup time of the worker and while downloading 
    #the workflow and input data to the worker. The state PAUSED is not 
    #currently used. The FAILING state can occur if the workflow engine
    #crashed, after clean-up or if the workflow itself failed, the state 
    #will be FAILED.
    #
    #The job might at any time be set to the state CANCELLING by the user, 
    #which will stop execution of the workflow, leading to the state 
    #CANCELLED.
    #
    #If the workflow execution completed the state will be set to COMPLETE, 
    #after which the workflow result data should be available by using
    #get_job_outputs_doc().
    #
    #If data about the job has been lost (probably because it's too old 
    #or has been deleted by the user), the state will be DESTROYED.
	class Status
    	NEW = "NEW"
        QUEUED = "QUEUED"
        INITIALISING = "INITIALISING"
        PAUSED = "PAUSED"
        FAILING = "FAILING"
        CANCELLING = "CANCELLING"
        CANCELLED = "CANCELLED"
        COMPLETE = "COMPLETE"
        FAILED = "FAILED"
        DESTROYED = "DESTROYED"
        FINISHED = [COMPLETE, CANCELLED, DESTROYED, FAILED]
        ALL = [NEW, QUEUED, INITIALISING, FAILING, 
                   CANCELLING, CANCELLED, COMPLETE, FAILED, DESTROYED]
    
        #Return True if the status is a finished status.
        #
        #This would normally include COMPLETE, CANCELLED, DESTROYED and FAILED.
        def Status.finished?(status)
            return FINISHED.include?(status)
        end
        
        #Check if a string is a valid status.
        def Status.valid?(status)
            ALL.include?(status)
        end
	end
        
    #Client library for accessing a Taverna Remote execution service.
    #
    #Since the service is a rest interface, this library reflects that to 
    #a certain degree and many of the methods return URLs to be used by 
    #other methods.
    # 
    # The main methods of interest are - in order of a normal execution:
    # 
    #    execute_sync() -- Given a scufl document or the URL for a previously 
    #        uploaded workflow, and data as a hash or URL for previously
    #        uploaded data, submit job for execution, wait for completion 
    #        (or a timeout) and retrieve results. This is a blocking 
    #        convenience method that can be used instead of the methods below.
    # 
    #    upload_workflow() -- Given a scufl document as a string, upload the
    #        workflow to the server for later execution. Return the URL for the
    #        created workflow resource that can be used with submit_job()
    #        
    #    upload_data()-- Given a hash of input values to a
    #        workflow run, upload the data to the user's collection.
    #        Return the URL for the created data resource that can be used with 
    #        submit_job()
    #    
    #    submit_job() -- Given the URL for a workflow resource and optionally
    #        the URL for a input data resource, submit the a to the server 
    #        to be executed. Return the URL to the created job resource.
    #    
    #    get_job_status() -- Get the status of the job. Return one of the values from
    #        Status.
    #        
    #    finished?() -- Return True if the job is in a finished state. Note 
    #        that this also includes failed states.
    #
    #    wait_for_job() -- Wait until job has finished execution, or a maximum
    #        timeout is exceeded.
    #                   
    #    get_job_outputs() -- Get the outputs produced by job.  Return a  
    #        hash which values are strings, lists of strings, 
    #        or deeper lists.
    #        
    #Most or all of these methods might in addition to stated exceptions also raise
    #Net::HTTPError or InvalidResponseError if anything goes wrong in communicating with the service.
	class Client
    
    	#Name spaces used by various XML documents.
  	    NAMESPACES = {
			  :xscufl => 'http://org.embl.ebi.escience/xscufl/0.1alpha',
			  :baclava => 'http://org.embl.ebi.escience/baclava/0.1alpha',
			  :service => 'http://taverna.sf.net/service',
			  :xlink => 'http://www.w3.org/1999/xlink',
			  :dcterms => 'http://purl.org/dc/terms/'
		}

		#Mime types used by the rest protocol.
		#
		# See net.sf.taverna.service.interfaces.TavernaConstants.java
		MIME_TYPES = {
			:rest => 'application/vnd.taverna.rest+xml', # For most of the rest documents
			:scufl => 'application/vnd.taverna.scufl+xml', # For Taverna workflows
			:baclava => 'application/vnd.taverna.baclava+xml', # For Taverna's Baclava data documents
			:report => 'application/vnd.taverna.report+xml', # For Taverna's internal progress reports
			:console => 'text/plain' # For Taverna's console
		}


		DEFAULT_TIMEOUT = 5 * 60 # in seconds
		DEFAULT_REFRESH = 0.5 # in seconds
	
		#Construct a Taverna remote execution service client accessing the service
		#at the given base URL.  
		#
		#Note that this constructor will not attempt to verify the URL or the 
		#credentials. To verify, call get_user_url() which requires authentication.
		#
		#url -- The base URL for the service, normally ending in /v1/, for example:
		#    "http://myserver.com:8080/tavernaService/v1/"
		#
		#username -- The username of a user that has been previously created or 
		#    registered in the web interface of the service.
		#    
		#password -- The password of the user. Note that the password will be sent
		#   over the wire using unencrypted HTTP Basic Auth, unless the URL starts
		#	with "https".
		def initialize(url, username, password)
			@url = url
			@username = username
			@password = password
		end
        
		#private
		
		#Get the capabilities document as a REXML::Document 
		#
		#This document contains the links to the main collections of the service.
		def get_capabilities_doc
			url = URI.parse(@url)
			request = Net::HTTP::Get.new(url.path)
			request['Accept'] = MIME_TYPES[:rest]
			request.basic_auth @username, @password
			response = Net::HTTP.start(url.host, url.port) {|http|
			  http.request(request)
			}
			response.value
			REXML::Document.new(response.body)
		end
        
		#Get the URL for the current user's home on the server.
		def get_user_url
			capabilities_doc = get_capabilities_doc()
			#currentUser = capabilities_doc.root.elements["{#{NAMESPACES[:service]}}currentUser"]
			current_user = capabilities_doc.root.elements['currentUser']
			current_user_url = current_user.attributes.get_attribute_ns(NAMESPACES[:xlink], 'href').value
			
			url = URI.parse(current_user_url)
			request = Net::HTTP::Get.new(url.path)
			request['Accept'] = MIME_TYPES[:rest]
			request.basic_auth @username, @password
			response = Net::HTTP.start(url.host, url.port) {|http|
				http.request(request)
			}
			response.error! unless response.kind_of?(Net::HTTPSuccess) or response.kind_of?(Net::HTTPRedirection)
			response.header['Location']
		end
 
		#Get the user document as an REXML::Document object. 
		#
		#This document contains the links to the user owned collections, 
		#such as where to upload workflows and jobs.
		def get_user_doc
			url = URI.parse(get_user_url())
			request = Net::HTTP::Get.new(url.path)
			request['Accept'] = MIME_TYPES[:rest]
			request.basic_auth @username, @password
			response = Net::HTTP.start(url.host, url.port) {|http|
				http.request(request)
			}
			response.value
			REXML::Document.new(response.body)
		end
		
		#Get the URL to a user-owned collection. 
		#
		#collectionType -- The collection, either "workflows" or "datas"
		def get_user_collection_url(collection)
			user_doc = get_user_doc()

			#collections = user_doc.root.elements["{#{NAMESPACES[:service]}}#{collection}"]
			collections = user_doc.root.elements[collection]
			return collections.attributes.get_attribute_ns(NAMESPACES[:xlink], 'href').value
		end
		
		#Get the URL to the output document for a job.
		#
		#It generally only makes sense to call this function if
		#get_job_status() == Status::COMPLETED, but no check is enforced here.
		#
		#Return the URL to a data document produced by the job, or None if the
		#job has not (yet) produced any output.
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		def get_job_outputs_url(job_url)
			job_document = get_xml_doc(job_url)
			#outputs_element = job_document.root.elements["{#{NAMESPACES[:service]}}outputs"]
			outputs_element = job_document.root.elements['outputs']
			return nil if not outputs_element
			outputs_element.attributes.get_attribute_ns(NAMESPACES[:xlink], 'href').value 
		end
		
		#Get the output document for a job.
		#
		#Return the output document as an REXML::Document object, or None
		#if the job didn't have an output document (yet). This document can be
		#parsed using parse_data_doc().
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		def get_job_outputs_doc(job_url)
			outputs_url = get_job_outputs_url(job_url)
			return nil if not outputs_url
			get_xml_doc(outputs_url, MIME_TYPES[:baclava])
		end   
		
		#Retrieve an XML document from the given URL.
		#
		#Return the retrieved document as a REXML::Document.
		#
		#url -- The URL to a resource retrievable as an XML document
		#
		#mimeType -- The mime-type to request using the Accept header, by default
		#	MIME_TYPES[:rest]
		def get_xml_doc(doc_url, mimeType=MIME_TYPES[:rest])
			url = URI.parse(doc_url)			
			request = Net::HTTP::Get.new(url.path)
			request['Accept'] = mimeType
			request.basic_auth @username, @password
			response = Net::HTTP.start(url.host, url.port) {|http|
			  http.request(request)
			}
			response.value
			REXML::Document.new(response.body)
		end
			
		#Return the size of an XML document from the given URL without
		#fetching the document.
		#
		#Return the size of a XML document .
		#
		#url -- The URL to a resource find the size of
		#
		#mimeType -- The mime-type to request using the Accept header, by default
		#	MIME_TYPES[:rest]
		def get_xml_doc_size(doc_url, mimeType=MIME_TYPES[:rest])
			url = URI.parse(doc_url)			
			request = Net::HTTP::Head.new(url.path)
			request['Accept'] = mimeType
			request.basic_auth @username, @password
			response = Net::HTTP.start(url.host, url.port) {|http|
			  http.request(request)
			}
			response.content_length
		end
   
		#Parse a data document as returned from get_job_outputs_doc().
		#
		#Return a hash where the keys are strings, matching the names of 
		#	ports of the workflow. The values are Document::Data objects. 
		#	
		#xml -- A data document as a REXML::Document. This data document can be created
		#	using create_data_doc()
		def parse_data_doc(xml_document)
			Baclava::Reader.read(xml_document)
		end
		
		#Upload a data document to the current user's collection.
		#
		#Return the URL of the created data resource.
		#
		#xml -- A data document as a REXML::Document. This data document can be created
		#	using create_data_doc()
		#
		#Raises:
		#	CouldNotCreateError -- If the service returned 200 OK instead of
		#		creating the resource
		def upload_data_doc(xml_document)
			datas_url = get_user_collection_url("datas")
			upload_to_collection(datas_url, xml_document.to_s, MIME_TYPES[:baclava])
		end
		
		#Tests if the url is valid for this server
		def url_valid?(url)
		  url = URI.parse(url)
		  req = Net::HTTP::Head.new(url.path)
		  req.basic_auth @username, @password
		  Net::HTTP.start(url.host, url.port) {|http|
			http.request(req)
		  }.kind_of?(Net::HTTPSuccess)
		end
					
		#Upload data by POST-ing to given URL. 
		#
		#Return the URL of the created resource if the request succeeded with
		#201 Created.
		#
		#Raises:
		#	CouldNotCreateError -- If the service returned 200 OK instead of
		#		creating the resource
		#	Net::HTTPError -- If any other HTTP result code (including errors) 
		#		was returned
		#
		#url -- The URL of the collection of where to POST, 
		#	normally retrieved using get_user_collection_url().
		#
		#data -- The data to upload as a string
		#
		#content_type -- The MIME type of the data to upload. Typically the value
		#	of one of the MimeTypes constants. For data uploaded to the "datas" user 
		#	collection this would be MIME_TYPES[:baclava], and for workflow to the "
		#	workflows" collection, MIME_TYPES[:scufl]. Any other XML documents from 
		#	the NAMESPACES[:service] namespace has the mime type MIME_TYPES[:rest]
		def upload_to_collection(url, data, content_type)
			url = URI.parse(url)    	
			request = Net::HTTP::Post.new(url.path)
			request.body = data
			request['Accept'] = MIME_TYPES[:rest]
			request['Content-Type'] = content_type
			request.basic_auth @username, @password
			response = Net::HTTP.start(url.host, url.port) {|http|
			  http.request(request)
			}
			response.value			
			raise CouldNotCreateError(url, response) unless response.kind_of?(Net::HTTPCreated)
			response.header['Location']
		end
	
		#Create a data document to be uploaded with upload_data_doc(). 
		#
		#Return the data document a REXML::Document. This data document can be parsed using
		#parse_data_doc()
		#
		#hash -- A hash where the keys are strings, matching the names of input
		#	ports of the workflow to run. The values are Document::Data objects. 
		#
		def create_data_doc(hash)
			Baclava::Writer.write_doc(hash)
		end
		
		#Create a job document for submission with submit_job().
		#
		#Return the job document as XML.
		#
		#workflow_url -- The URL of a workflow previously uploaded using
		#	upload_workflow()
		#
		#inputs_url -- The (optional) URL of a input document previously
		#	uploaded using upload_data_doc()
		def create_job_doc(workflow_url, inputs_url=nil)
			xml = Builder::XmlMarkup.new
			xml.instruct!
			REXML::Document.new(xml.job('xmlns' => NAMESPACES[:service], 'xmlns:xlink' => NAMESPACES[:xlink]) {
				xml.inputs('xlink:href' => inputs_url) if inputs_url
				xml.workflow('xlink:href' => workflow_url)
			})
		end

		#Submit a job to be queued for execution on the server.
		#
		#Return the URL to the job resource.
		#
		#job_document -- A job document created with create_job_doc() specifying
		#	the workflow to run with which inputs.
		#	
		#Raises:
		#	CouldNotCreateError -- If the service returned 200 OK instead of
		#		creating the resource
		def submit_job_doc(job_document)
			jobsURL = get_user_collection_url("jobs")
			upload_to_collection(jobsURL, job_document.to_s, MIME_TYPES[:rest])    
		end
		
		public
		
		#Get the status of a previously submitted job.
		#
		#Return the status as a string, one of the values from Status.
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		def get_job_status(job_url)
			job_document = get_xml_doc(job_url)
			#status = job_document.elements["{#{NAMESPACES[:service]}}status"]
			status = job_document.root.elements['status']
			# TODO: For future checks, use: 
			#status_url = status.attributes.get_attribute_ns(NAMESPACES[:xlink], 'href').value
			status.text
		end
		
		#Get the date a previously submitted job was created.
		#
		#Return the date as a Datetime object.
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		def get_job_created_date(job_url)
			job_document = get_xml_doc(job_url)
			#created = job_document.elements["{#{NAMESPACES[:dcterms]}}created"]
			created = job_document.root.elements['dcterms:created'].text
			DateTime.parse(created)
		end
		
		#Get the date a previously submitted job was last modified.
		#
		#Return the date as a Datetime object.
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		def get_job_modified_date(job_url)
			job_document = get_xml_doc(job_url)
			#modified = job_document.elements["{#{NAMESPACES[:dcterms]}}modified"]
			modified = job_document.root.elements['dcterms:modified'].text
			DateTime.parse(modified)
		end
		
		#Get the job's internal progress report. This might be available
		#while the job is running.
		#
		#Return the internal progress report as a Document::Report object.
		#
		#job_url -- The URL to a job resource previously created using submit_job().
		def get_job_report(job_url)
			job_document = get_xml_doc(job_url)
			#report_element = job_document.elements["{#{NAMESPACES[:service]}}report"]
			report_element = job_document.root.elements['report']
			report_url = report_element.attributes.get_attribute_ns(NAMESPACES[:xlink], 'href').value
			# TODO: Cache report_url per job
			job_report_document = get_xml_doc(report_url, MIME_TYPES[:report])
			Document::Report.from_document(job_report_document)
		end
			
		#Get the outputs of a job.
		#
		#Return the job outputs as a hash where the keys are strings, 
		#matching the names of output ports of the workflow. The values are
		#Document::Data objects. If no outputs exists, nil is returned instead.
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		def get_job_outputs(job_url)
			job_outputs = get_job_outputs_doc(job_url)
			return nil unless job_outputs
			parse_data_doc(job_outputs)
		end
	
		#Get the size of the outputs of a job.
		#
		#Return the size of the outputs of a job in kilobytes.
		#If no outputs exists, nil is returned instead.
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		def get_job_outputs_size(job_url)
			outputs_url = get_job_outputs_url(job_url)
			return nil if not outputs_url
			get_xml_doc_size(outputs_url, MIME_TYPES[:baclava])
		end
	
		#Check if a job has finished in one way or another. 
		#
		#Note that the job might have finished unsuccessfully. To check 
		#if a job is actually complete, check::
		#
		#    get_job_status(job_url) == Status::COMPLETE.
		#
		#Return True if the job is in a finished state, that is that the
		#Status.finished?(get_job_status()) is True.
		#
		#job_url -- The URL to a job resource previously created using
		#    #submit_job().
		#
		def finished?(job_url)
			status = get_job_status(job_url)
			Status.finished?(status)
		end
		
		#Submit a job to be queued for execution on the server.
		#
		#Return the URL to the created job resource.
		# 
		#workflow_url -- The URL of a workflow previously uploaded using
		#    upload_workflow()
		# 
		#inputs_url -- The (optional) URL of a input resource previously
		#    uploaded using upload_data()
		#    
		#Raises:
		#    CouldNotCreateError -- If the service returned 200 OK instead of
		#        creating the resource    
		#
		def submit_job(workflow_url, inputs_url=nil)
			job_document = create_job_doc(workflow_url, inputs_url)
			submit_job_doc(job_document)
		end
		
		#Upload data to be used with submit_job().
		#
		#Return the URL to the created data resource.
		#
		#hash -- A hash where the keys are strings, matching the names of input
		#	ports of the workflow to run. The values can be strings, lists of strings, or deeper
		#	lists.
		#	
		#Raises:
		#	CouldNotCreateError -- If the service returned 200 OK instead of
		#		creating the resource    
		def upload_data(hash)
			inputs = create_data_doc(hash)
			upload_data_doc(inputs)
		end
		
		#Checks if the workflow exists on the server
		#			
		#workflow_url -- The URL to a workflow previously uploaded using 
		#	upload_workflow().
		def workflow_exists?(workflow_url)
			url_valid?(workflow_url)
		end
		
		#Checks if the username and password is valid for the service
		def service_valid?
			begin
				get_user_url
				true
			rescue
				false
			end
		end
		
		#Upload a workflow XML document to the current users' collection.
		#
		#Return the URL of the created workflow resource.
		#
		#workflow_xml -- The Taverna scufl workflow as a string
		#
		#Raises:
		#	CouldNotCreateError -- If the service returned 200 OK instead of
		#		creating the resource
		def upload_workflow(workflow_xml)
			workflows_url = get_user_collection_url("workflows")
			upload_to_collection(workflows_url, workflow_xml, MIME_TYPES[:scufl])
		end
		
		#Wait (blocking) for a job to finish, or until a maximum timeout 
		#has been reached.
		#
		#Return the status of the job. If the 
		#
		#job_url -- The URL to a job resource previously created using
		#	submit_job().
		#
		#timeout -- The maximum number of seconds (as a float) to wait for job.
		#	The default value is DEFAULT_TIMEOUT.
		#
		#refresh -- In seconds (as a float), how often to check the job's 
		#	status while waiting. The default value is DEFAULT_REFRESH.
		def wait_for_job(job_url, timeout=DEFAULT_TIMEOUT, refresh=DEFAULT_REFRESH)
			now = Time.now
			_until = now + timeout
			while _until > Time.now and not finished?(job_url)
				now = Time.now # finished?() might have taken a while
				sleep [[refresh, _until-now].min, 0].max
				now = Time.now # after the sleep
			end         
			get_job_status(job_url)
		end
		
		#Execute a workflow and wait until it's finished. 
		#
		#This will block until the workflow has been executed by the server, and
		#return the result of the workflow run.
		#
		#Return the parsed output document as a hash where the keys are 
		#strings, matching the names of output ports of the workflow. The 
		#values are Document::Data objects. If the workflow
		#did not produce any output, nil might be returned instead.
		#
		#workflow_xml -- The workflow as a Taverna scufl XML string. This *or* the 
		#	workflow_url parameter is required.
		#
		#workflow_url -- The URL to a workflow previously uploaded using 
		#	upload_workflow(). This *or* the workflow_xml parameter is required.
		#	
		#inputs -- The (optional) inputs to the workflow, either as a Baclava 
		#	XML document (string), or as a hash where the keys are 
		#	strings, matching the names of input ports of the workflow. The 
		#	values can be strings, lists of strings, or deeper lists. 
		#
		#timeout -- The maximum number of seconds (as a float) to wait for job.
		#	The default value is DEFAULT_TIMEOUT.
		#
		#refresh -- In seconds (as a float), how often to check the job's 
		#	status while waiting. The default value is DEFAULT_REFRESH.
		#
		#Raises:
		#	NotCompleteError -- If the job did not complete, for instance because
		#		the timeout was reached before completion.
		#	
		#	urllib2.HTTPError -- If any step in submitting or requesting the status and
		#		result of the job failed.
		def execute_sync(workflow_xml=nil, workflow_url=nil, inputs=nil, 
						timeout=DEFAULT_TIMEOUT, refresh=DEFAULT_REFRESH)
			raise TypeError.new("workflow_xml or worklowURL must be given") unless workflow_xml or workflow_url 
			raise TypeError.new("Only one of workflow_xml and workflow_url can be given") if workflow_xml and workflow_url
	 
			workflow_url = upload_workflow(workflow_xml) if workflow_xml
			inputs_url = upload_data(inputs) if inputs
			
			job_url = submit_job(workflow_url, inputs_url)
			status = wait_for_job(job_url, timeout, refresh)

			raise NotCompleteError.new(job_url, status) if status != Status::COMPLETE
	
			get_job_outputs(job_url)
		end
		
	end
	
end

