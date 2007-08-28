
require 'rexml/document'
require 'net/http'

class JobsController < ApplicationController

  def edit
  end

  def index
    redirect_to :action => 'list'
  end

  def list
  end

  def serverlist
    @job = 'no jobs'
    url = URI.parse('http://localhost:8080/')
    Net::HTTP.start(url.host, url.port) {|http|
      req = Net::HTTP::Get.new('/taverna-service-1.0.0/v1/users/myexperiment/jobs')
      req['Accept'] = 'application/vnd.taverna.rest+xml'
      req.basic_auth 'myexperiment', 'myexperiment'
      response = http.request(req)
      @job = response.body
    }
  end

  def submit
    redirect_to :action => 'list'
  end


  def new
    @workflow = Workflow.find(params[:id])
    @inputs = get_sources(@workflow)
  end

  def show
    @job = Job.find(params[:id])
    @status = @job.status_string
    @workflow = Workflow.find(@job.workflow_id)
  end

  def create

    @job = Job.new()

#   params[:job].each do |key, value|
#     puts key
#     puts value
#   end 

    @job.workflow_id = params[:workflow_id]

# add job to server here

#   @response = 'no response'
#   url = URI.parse('http://localhost:8080/')
#   Net::HTTP.start(url.host, url.port) { |http|
#     
#     req = Net::HTTP::Post.new('/taverna-service-1.0.0/v1/users/myexperiment/workflows')

#      req['Accept'] = 'application/vnd.taverna.rest+xml'

#     req['Content-Type'] = 'application/vnd.taverna.scufl+xml'
#     req.basic_auth 'myexperiment', 'myexperiment'
#     req.body = File.new(Workflow.find(params[:id]).scufl).read
#     response = http.request(req)
#     @location = response['Location']
#     
#     xml = Builder::XmlMarkup.new
#     xml.instruct!

#     req = Net::HTTP::Post.new('/taverna-service-1.0.0/v1/users/myexperiment/jobs')
#     req['Accept'] = 'application/vnd.taverna.rest+xml'
#     req['Content-Type'] = 'application/vnd.taverna.rest+xml'
#     req.basic_auth 'myexperiment', 'myexperiment'
#     req.body = xml.job ('xmlns' => 'http://taverna.sf.net/service', 'xmlns:xlink' => 'http://www.w3.org/1999/xlink') {
#                  xml.data 
#                  xml.workflow ('xlink:href' => @location)
#                }
#     response = http.request(req)
#     @response = response['Location']
#   }
#   
#   serverjob_id = response['Location']

    serverjob_id = '123123'

# end of add job to server here

    if (params[:job] == nil)
      params[:job] = [ ]
    end
     
    @job.user_id = session[:user_id]
    @job.started_at = DateTime.now
    @job.status = Job.running
    @job.server_job = serverjob_id
    @job.inputs = Marshal.dump(params[:job])

    if @job.save
      flash[:notice] = 'Job submission succeeded'
    else 
      flash[:notice] = 'Job submission failed'
    end 

    render :action => 'list'

  end

  protected

  def get_sources(workflow)

    parser = Scufl::Parser.new
    model  = parser.parse(File.new(workflow.scufl, "r").read)

    return model.sources
  end

  def status_string(job)

    if (job.status == Job.running)
      return "Running"
    elsif (job.status == Job.completed)
      return "Completed"
    elsif (job.status == Job.failed)
      return "Failed"
    elsif (job.status == Job.cancelled)
      return "Cancelled"
    else
      return "Unknown"
    end

  end

end
