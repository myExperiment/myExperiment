# myExperiment: app/controllers/user_reports_controller.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class UserReportsController < ApplicationController

  before_filter :find_object

  def create
    UserReport.create(:user => current_user, :subject => @object)
    respond_to do |format|
      format.html { head 200 }
    end
  end

  private

  def find_object
    # ensure that the object type is valid
    unless ["Comment", "Message"].include?(params[:subject_type])
      respond_to do |format|
        format.html { head 400 }
      end
    else
      @object = Object.const_get(params[:subject_type]).find_by_id(params[:subject_id])

      if @object.nil?
        respond_to do |format|
          format.html { render(:text => "Report failed. #{params[:subject_type]} not found.", :status => 404) }
        end
      elsif !Authorization.check('view', @object, current_user)
        respond_to do |format|
          format.html { render(:text => "Report failed. You are not authorized to view this #{params[:subject_type]}.", :status => 401) }
        end
      end
    end
  end
end
