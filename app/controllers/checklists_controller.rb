# myExperiment: app/controllers/checklists_controller.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class ChecklistsController < ApplicationController

  before_filter :find_and_auth_resource_context
  before_filter :find_checklist

  def show
  end

private

  def find_and_auth_resource_context
    @context = extract_resource_context(params)

    if @context.nil?
      render_404("Checklist context not found.")
    elsif !Authorization.check('view', @context, current_user)
      render_401("You are not authorized to view the checklists of this resource.")
    end
  end

  def find_checklist

    unless params[:action] == 'index'
      @checklist = @context.research_object.checklists.find_by_slug(params[:id])

      if @checklist.nil?
        render_404("Checklist not found.")
        return
      end
    end
  end
end
