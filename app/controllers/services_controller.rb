# myExperiment: app/controllers/services_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController

  include ApplicationHelper

  before_filter :find_service,  :only => [:show]
  
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

        @pivot, problem = calculate_pivot(

            :pivot_options  => Conf.pivot_options,
            :params         => params,
            :user           => current_user,
            :search_models  => [Service],
            :search_limit   => Conf.max_search_size,

            :locked_filters => { 'CATEGORY' => 'Service' },

            :active_filters => ["CATEGORY", "TYPE_ID", "TAG_ID", "USER_ID",
                                "LICENSE_ID", "GROUP_ID", "WSDL_ENDPOINT",
                                "CURATION_EVENT", "SERVICE_PROVIDER",
                                "SERVICE_COUNTRY", "SERVICE_STATUS"])

        flash.now[:error] = problem if problem

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

