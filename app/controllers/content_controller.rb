# myExperiment: app/controllers/content_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContentController < ApplicationController

  include ApplicationHelper

  def index
    respond_to do |format|
      format.html do

        @pivot, problem = calculate_pivot(

            :pivot_options    => Conf.pivot_options,
            :params           => params,
            :user             => current_user,
            :search_models    => [Workflow, Blob, Pack, Service],
            :search_limit     => Conf.max_search_size,

            :active_filters   => ["CATEGORY", "TYPE_ID", "TAG_ID", "USER_ID",
                                  "LICENSE_ID", "GROUP_ID", "WSDL_ENDPOINT",
                                  "CURATION_EVENT", "SERVICE_PROVIDER",
                                  "SERVICE_COUNTRY", "SERVICE_STATUS"])

        flash.now[:error] = problem if problem

        @query = params[:query]

        # index.rhtml
      end
#     format.rss do
#       #@workflows = Workflow.find(:all, :order => "updated_at DESC") # list all (if required)
#       render :action => 'index.rxml', :layout => false
#     end
    end
  end

end

