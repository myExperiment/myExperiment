# myExperiment: app/controllers/contributions_controller.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContributionsController < ApplicationController

  before_filter :get_context, :only => [:curation]

  def curation
    @events = CurationEvent.find_all_by_object_type_and_object_id(@contributable.class.name, @contributable.id)
  end

private

  def get_context
    begin

      # Determine the class name of the model
      klass_name = params[:contributable_type].singularize.camelize

      # Process model aliases (e.g. File => Blob)
      klass_name = Conf.model_aliases[klass_name] if Conf.model_aliases[klass_name]

      @contributable = Object.const_get(klass_name).find_by_id(params[:contributable_id])

      # Abort if the contributable does not exist
      return false if @contributable.nil?

      # Abort if we're not allowed to see this contributable
      return false unless Authorization.check(:action => 'view', :object => @contributable, :user => current_user)

    rescue

      # In case the const_get doesn't find anything
      return false
    end

    return true
  end
end

