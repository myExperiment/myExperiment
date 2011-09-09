# myExperiment: app/controllers/services_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController

  include ApplicationHelper

  before_filter :find_service,  :only => [:show]
  before_filter :find_services, :only => [:all]
  
  # GET /algorithms;search
  def search
#   @query = params[:query] || ''
#   @query.strip!
#   
#   @contributables = (Conf.solr_enable && !@query.blank?) ? Algorithm.find_by_solr(@query, :limit => 100).results : []
#   @total_count = (Conf.solr_enable && !@query.blank?) ? Algorithm.count_by_solr(@query) : 0
#   
#   respond_to do |format|
#     format.html # search.rhtml
#   end
  end
  
  # GET /services
  def index
    respond_to do |format|
      format.html {
        @pivot_options = pivot_options

        begin
          expr = parse_filter_expression(params["filter"]) if params["filter"]
        rescue Exception => ex
          puts "ex = #{ex.inspect}"
          flash.now[:error] = "Problem with query expression: #{ex}"
          expr = nil
        end

        @pivot = contributions_list(Contribution, params, current_user,
            :lock_filter => { 'CATEGORY' => 'Service' },
            :filters     => expr)

        @query = params[:query]
        @query_type = 'services'

        # index.rhtml
      }
    end
  end
  
  # GET /services/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end
  
  # GET /service/1
  def show
    redirect_to(@contributable.uri)
  end
  
  protected
  
  def find_services
    @contributables = Service.find(:all, 
                       :order => "created_at DESC",
                       :page => { :size => 20, 
                       :current => params[:page] })
  end
  
  def find_service
    begin
      service = Service.find(params[:id])
      
      @contributable = service
      
      @contributable_entry_url = url_for :only_path => false,
                          :host => base_host,
                          :id => @contributable.id

      @contributable_label                = @contributable.name
      @contributable_path                 = service_path(@contributable)

    rescue ActiveRecord::RecordNotFound
      error("Service not found", "is invalid")
      return false
    end
  end
  
  private
  
  def error(notice, message, attr=:id)
    flash[:error] = notice
     (err = Service.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to services_url }
    end
  end
end

