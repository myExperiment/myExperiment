$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'enactor/client'
require 'document/data'

class TcClient < Test::Unit::TestCase

	FIXTURES = File.join(File.dirname(__FILE__), "fixtures")
	
	TEST_SERVER="http://rpc269.cs.man.ac.uk:8180/remotetaverna/v1/"
	TEST_USER="snake"
	TEST_PW=IO.read("#{FIXTURES}/password.txt").strip
	
	# Test workflows
	ANIMAL_WF=IO.read("#{FIXTURES}/animal.xml")
	COLOUR_ANIMAL_WF=IO.read("#{FIXTURES}/colouranimal.xml")
		
    def setup
    	@service = Enactor::Client.new(TEST_SERVER, TEST_USER, TEST_PW)
    end
	
	def test_connect
		capabilities_doc = @service.get_capabilities_doc()
        #users = capabilities.elements["{http://taverna.sf.net/service}users"]
        users = capabilities_doc.root.elements["users"]
        users_url = users.attributes.get_attribute_ns('http://www.w3.org/1999/xlink', 'href').value
        assert_equal(TEST_SERVER  + "users", users_url)
	end
    
    def test_get_user_url
        user_url = @service.get_user_url()
        assert_equal(TEST_SERVER + "users/" + TEST_USER, user_url)
    end
    
    def test_get_user_collection_url
        workflow_url = @service.get_user_collection_url("workflows")
        assert_equal(TEST_SERVER + "users/" + TEST_USER + "/workflows", workflow_url)
        job_url = @service.get_user_collection_url("jobs")
        assert_equal(TEST_SERVER + "users/" + TEST_USER + "/jobs", job_url)
        data_url = @service.get_user_collection_url("datas")
        assert_equal(TEST_SERVER + "users/" + TEST_USER + "/data", data_url)
    end
    
    def test_upload_workflow
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        prefix = TEST_SERVER + "workflows/"
        assert(workflow_url.index(prefix) == 0)
    end
        
	def test_workflow_exists
        workflow_url = @service.upload_workflow(ANIMAL_WF)
		assert(@service.workflow_exists?(workflow_url))
		assert(!@service.workflow_exists?(workflow_url.chop))
	end
	
	def test_service_valid
		assert(@service.service_valid?)
		assert(!Enactor::Client.new(TEST_SERVER, TEST_USER, TEST_PW.chop).service_valid?)
	end
	
    def test_create_job
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_doc = @service.create_job_doc(workflow_url)
        #workflow_element = job_doc.elements["{http://taverna.sf.net/service}workflow"]
        workflow_element = job_doc.root.elements['workflow']
        assert_equal(workflow_url, workflow_element.attributes.get_attribute_ns('http://www.w3.org/1999/xlink', 'href').value)
    end
    
    def test_submit_job
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_url = @service.submit_job(workflow_url)
        prefix = TEST_SERVER + "jobs/"
        assert(job_url.index(prefix) == 0)
    end 
    
    def test_create_data
        inputs = {}
        inputs['colour'] = Document::Data.new('red')
        inputs['animal'] = Document::Data.new('snake')
        data_document = @service.create_data_doc(inputs)
        parsed = @service.parse_data_doc(data_document)
        assert_equal(inputs, parsed)
    end
    
    def test_upload_data
        inputs = {}
        inputs["colour"] = Document::Data.new("red")
        inputs["animal"] = Document::Data.new("snake")
        data_url = @service.upload_data(inputs)
        prefix = TEST_SERVER + "data/"
        assert(data_url.index(prefix) == 0)
    end
	
    def test_submit_job_with_data
        inputs = {}
        inputs["colour"] = Document::Data.new("red")
        inputs["animal"] = Document::Data.new("snake")
        workflow_url = @service.upload_workflow(COLOUR_ANIMAL_WF)
        data_url = @service.upload_data(inputs)
        job_url = @service.submit_job(workflow_url, data_url)
    end
	
    def test_get_job_status
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_url = @service.submit_job(workflow_url)
        status = @service.get_job_status(job_url)
        assert(Enactor::Status.valid?(status))
    end
        
    def test_get_job_created_date
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_url = @service.submit_job(workflow_url)
		time = @service.get_job_created_date(job_url)
		assert(time.kind_of?(DateTime))
    end
        
    def test_get_job_modified_date
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_url = @service.submit_job(workflow_url)
		time = @service.get_job_modified_date(job_url)
		assert(time.kind_of?(DateTime))
    end
        
    def test_finished
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_url = @service.submit_job(workflow_url)
        # Assuming our server is not VERY quick
        assert(!@service.finished?(job_url))
    end
                         
    def test_job_outputs_size
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_url = @service.submit_job(workflow_url)
        @service.wait_for_job(job_url, 30)
		assert_equal(481, @service.get_job_outputs_size(job_url))
    end
        
    def test_wait_for_job
        workflow_url = @service.upload_workflow(ANIMAL_WF)
        job_url = @service.submit_job(workflow_url)
        now = Time.now
        timeout = 1
        status = @service.wait_for_job(job_url, timeout)
        after = Time.now

        # Should be at least some milliseconds longer than the timeout
        assert(after - now > timeout)
        assert(!@service.finished?(job_url))
    end
        
    def test_execute
        # Note: This test might take a minute or so to complete
        results = @service.execute_sync(ANIMAL_WF)
        assert_equal(1, results.length)
        assert_equal("frog", results["animal"].value)
    end
        
    def test_execute_with_data
        # Note: This test might take a minute or so to complete
        inputs = {}
        inputs["colour"] = Document::Data.new("red")
        inputs["animal"] = Document::Data.new("snake")
        workflow_url = @service.upload_workflow(COLOUR_ANIMAL_WF)
        results = @service.execute_sync(nil, workflow_url, inputs)

        assert_equal(1, results.length)
        assert_equal("redsnake", results["coulouredAnimal"].value)
    end
        
    def test_execute_with_multiple_data
        # Note: This test might take a minute or so to complete
        inputs = {}
        inputs["colour"] = Document::Data.new(["red", "green"])
        inputs["animal"] = Document::Data.new(["rabbit", "mouse", "cow"])
        workflow_url = @service.upload_workflow(COLOUR_ANIMAL_WF)
        results = @service.execute_sync(nil, workflow_url, inputs)

        assert_equal(1, results.length)
        animals = results["coulouredAnimal"].value

		assert_equal(2, animals.length)
		animals = animals[0] + animals[1]
		assert_equal(6, animals.length)

        assert(animals.include?("redmouse"))
        assert(animals.include?("greenrabbit"))
        assert(!animals.include?("redsnake"))
    end
	
end