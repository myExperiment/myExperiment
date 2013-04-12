# myExperiment: app/controllers/user_reports_controller.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class UserReportsController < ApplicationController

  before_filter :find_object
  
  def create
    UserReport.create(:user => current_user, :subject => @object)
    render(:text => '[ reported ]', :status => 200)
  end

  private

  def find_object
    # ensure that the object type is valid
    unless ["Comment", "Message"].include?(params[:subject_type])
      render(:nothing => true, :status => 400)
    else
      @object = Object.const_get(params[:subject_type]).find_by_id(params[:subject_id])

      if @object.nil?
        render(:text => "Report failed. #{params[:subject_type]} not found.", :status => 404)
      elsif !Authorization.check('view', @object, current_user)
        render(:text => "Report failed. You are not authorized to view this #{params[:subject_type]}.", :status => 401)
      end
    end
  end
end
