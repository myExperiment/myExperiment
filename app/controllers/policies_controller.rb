# myExperiment: app/controllers/group_policies_controller.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

class PoliciesController < ApplicationController

  def show
    @policy = Policy.find(params[:id])

    unless current_user == @policy.contributor ||
           @policy.contributor_type == 'Network' && @policy.contributor.administrator?(current_user.id)
      render :code => 401
    end
  end

end
