# myExperiment: app/controllers/user_reports_controller.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

class UserReportsController < ApplicationController

  before_filter :find_object
  
  def create
    UserReport.create(:user => current_user, :subject => @object)
    render(:text => '[ reported ]')
  end

  private

  def find_object

    # ensure that user is logged in and that params[:user_id] matches
    return error if (current_user == 0 || (current_user.id.to_s != params[:user_id]))

    # ensure that the object type is valid
    return error unless ["Comment", "Message"].include?(params[:subject_type])

    object = Object.const_get(params[:subject_type]).find(params[:subject_id])

    # ensure that the object exists
    return error if object.nil?

    # ensure that the object is visible to the user
    return error unless Authorization.check(:action => 'read', :object => object, :user => current_user)

    @object = object

    true
  end

  def error
    render(:text => '400 Bad Request', :status => "400 Bad Request")
    false
  end
end

