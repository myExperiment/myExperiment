
require 'rexml/document'
require 'net/http'
require 'baclava/reader'
require 'baclava/writer'

class JobsController < ApplicationController
  
  @@USER_NAME = 'myexperiment'
  @@PASSWORD = 'myexperiment'
  
  @@HOST = 'http://localhost:8080'
  @@NAME = 'remotetaverna'
  @@VERSION = 'v1'
  @@PATH = "/#{@@NAME}/#{@@VERSION}"
  @@USER = "#{@@HOST}#{@@PATH}/users/#{@@USER_NAME}"
  
  def edit
  end
  
  def index
    redirect_to :action => 'list'
  end
  
  def list
    @jobs = Job.find_all_by_user_id(@session[:user_id])
    update_statuses(@jobs)
  end
  
  def create
    workflow_id = params[:workflow_id]
    
    remote_workflow = get_remote_workflow(@@USER, workflow_id)
    
    response = submit_job(@@USER, remote_workflow)      
    
    if response.kind_of?(Net::HTTPSuccess)
      job_location = response['Location']
      job_status = get_job_status(job_location)
      
      job = Job.create(:user_id => session[:user_id],
                       :workflow_id => workflow_id,
                       :status => job_status,
                       :server_job => job_location)
      
      redirect_to :action => 'show', :id => job.id
    else
      flash[:notice] = 'Error submitting job'
      redirect_to :action => 'list'
    end
  end
  
  def new
    @workflow = Workflow.find(params[:id])
    @inputs = get_sources(@workflow)
  end
  
  def show
    @job = Job.find(params[:id])
    @workflow = Workflow.find(@job.workflow_id)
    update_status @job
    @status = @job.status
    if @status == 'COMPLETE'
      @output_location = get_output_location(get_job(@job.server_job))
      @outputs = Baclava::Reader.read(get_output(@output_location))
    end
    #    puts '****************************************************************'
    #    puts Baclava::Writer.write(@output)
    #    puts '****************************************************************'
  end
  
  def input
    render :inline => "<li><%= text_field 'job', @name %></li>"
  end
  
  protected
  
  def get_sources(workflow)
    
    parser = Scufl::Parser.new
    model  = parser.parse(File.new(workflow.scufl, "r").read)
    
    return model.sources
  end
  
  private
  
  #Updates the status of a list of Jobs
  def update_statuses(jobs)
    for job in jobs do
      update_status(job)
    end
  end
  
  #Updates the status of a Job.
  #The current status is fetched from the server unless the status is 'COMPLETE' 
  def update_status(job)
    if not job.status == 'COMPLETE'
      job.update_attribute(:status, get_job_status(job.server_job))
    end        
  end  
  
  #Returns the RemoteWorkflow for the local workflow.
  #If no RemoteWorkflow exists the workflow is submitted to the server and
  #a RemoteWorkflow is created.
  #If a RemoteWorkflow does exist the server is checked to see if the remote copy
  #still exists; if not a new copy is submitted and the RemoteWorkflow is updated
  def get_remote_workflow(user_url, workflow_id)
    remote_workflow = RemoteWorkflow.find_by_workflow_id_and_server(workflow_id, user_url)
    
    if remote_workflow
      if not workflow_exists? remote_workflow
        workflow_location = submit_workflow(workflow_id)
        remote_workflow.update_attribute(:workflow_location, workflow_location)
      end
    else
      workflow_location = submit_workflow(user_url, workflow_id)
      remote_workflow = RemoteWorkflow.create(:workflow_id => workflow_id,
                                              :server => user_url,
                                              :workflow_location => workflow_location)
    end
    
    remote_workflow
  end
  
  #Submits a workflow to the server and returns the location of the workflow.
  def submit_workflow(user_url, workflow_id)
    url = URI.parse(user_url)
    req = Net::HTTP::Post.new(url.path + '/workflows')
    req.basic_auth @@USER_NAME, @@PASSWORD
    req['Content-Type'] = 'application/vnd.taverna.scufl+xml'
    req.body = File.new(Workflow.find(workflow_id).scufl).read
    response = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    response['Location']  
  end
  
  #Tests if a workflow exists on the server.
  def workflow_exists?(remote_workflow)
    url = URI.parse(remote_workflow.workflow_location)
    req = Net::HTTP::Head.new(url.path)
    req.basic_auth @@USER_NAME, @@PASSWORD
    Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }.kind_of?(Net::HTTPSuccess)
  end
  
  #Submits a job to the server
  def submit_job(user_url, remote_workflow)
    url = URI.parse(user_url)
    req = Net::HTTP::Post.new(url.path + '/jobs')
    req.basic_auth @@USER_NAME, @@PASSWORD
    req['Accept'] = 'application/vnd.taverna.rest+xml'
    req['Content-Type'] = 'application/vnd.taverna.rest+xml'
    req.body = build_job_xml(remote_workflow)
    Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
  end
  
  #Returns the status of a job as a string
  def get_job_status(job_location)
    url = URI.parse(job_location)
    req = Net::HTTP::Get.new(url.path + '/status')
    req.basic_auth @@USER_NAME, @@PASSWORD
    response = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    if response.kind_of?(Net::HTTPSuccess)
      response.body
    else
        'UNKNOWN'
    end
  end
  
  #Returns the xml job report
  def get_job_report(job_location)
    url = URI.parse(job_location)
    req = Net::HTTP::Get.new(url.path + '/report')
    req.basic_auth @@USER_NAME, @@PASSWORD
    req['Accept'] = 'application/vnd.taverna.rest+xml'
    Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }.body
  end
  
  #Returns the xml for the job
  def get_job(job_location)
    url = URI.parse(job_location)
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth @@USER_NAME, @@PASSWORD
    req['Accept'] = 'application/vnd.taverna.rest+xml'
    Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }.body
  end
  
  #Returns the output baclava document
  def get_output(output_location)
    url = URI.parse(output_location)
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth @@USER_NAME, @@PASSWORD
    req['Accept'] = 'application/vnd.taverna.baclava+xml'
    Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }.body
  end  
  
  #Builds an xml job to send to the server
  #TODO need to add input data
  def build_job_xml(remote_workflow)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.job ('xmlns' => 'http://taverna.sf.net/service', 'xmlns:xlink' => 'http://www.w3.org/1999/xlink') {
      xml.data 
      xml.workflow ('xlink:href' => remote_workflow.workflow_location)
    }
  end
  
  def get_jobs(xml)
    jobs = []
    document = REXML::Document.new(xml)
    
    element = document.root
    element.each_element('job') { |job_element|  add_job(jobs, job_element)}
    
    jobs 
  end
  
  def add_job(jobs, element)
    job = {}
    jobs << job
    
    job[:href] = element.attribute('xlink:href')
    
    element.each_element('status') { |status| job[:status] = status.text }
    
  end
  
  def get_output_location(xml)
    output = ''
    document = REXML::Document.new(xml)
    
    element = document.root
    element.each_element('outputs') { |element| output = element.attribute('xlink:href').value }
    
    output 
  end
  
  def get_baclava(xml)
    document = REXML::Document.new(xml)
    
    element = document.root
    element.each_element('baclava') { |baclava| return baclava.text }
    
  end
  
  
end
