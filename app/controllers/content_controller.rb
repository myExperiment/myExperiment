# myExperiment: app/controllers/content_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContentController < ApplicationController

  include ApplicationHelper

  def index
    respond_to do |format|
      format.html do
        @pivot_options = pivot_options

        begin
          expr = parse_filter_expression(params["filter"]) if params["filter"]
        rescue Exception => ex
          puts "ex = #{ex.inspect}"
          flash.now[:error] = "Problem with query expression: #{ex}"
          expr = nil
        end

        @pivot = contributions_list(Contribution, params, current_user,
            :filters => expr, :arbitrary_models => true)

        # index.rhtml
      end
#     format.rss do
#       #@workflows = Workflow.find(:all, :order => "updated_at DESC") # list all (if required)
#       render :action => 'index.rxml', :layout => false
#     end
    end
  end

end

