# myExperiment: app/controllers/activities_controller.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class ActivitiesController < ApplicationController

  def feature

    context = extract_resource_context(params)
    render_404("Activity context not found.") if context.nil?
    render_401("Not authorized.") unless Authorization.check('edit', context, current_user)

    activity = context.activities.find(params[:id].to_i)
    render_404("Activity not found.") if activity.nil?

    case request.method
    when :put
      activity.update_attribute(:featured, true)

    when :delete
      activity.update_attribute(:featured, false)
    end

    redirect_to context
  end

end

