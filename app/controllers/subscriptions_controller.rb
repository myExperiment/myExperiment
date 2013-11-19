# myExperiment: app/controllers/subscriptions_controller.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class SubscriptionsController < ApplicationController

  before_filter :find_and_auth_resource_context
  before_filter :find_subscription

  def update
    current_user.subscriptions.create(:objekt => @context) unless @subscription
    redirect_to @context
  end

  def destroy
    current_user.subscriptions.delete(@subscription) if @subscription
    redirect_to @context
  end

  private

  def find_and_auth_resource_context
    @context = extract_resource_context(params)

    if @context.nil?
      render_404("Subscription context not found.")
    elsif !Authorization.check('view', @context, current_user)
      render_401("You are not authorized to view the subscription status of this resource.")
    end
  end
  
  def find_subscription
    @subscription = current_user.subscriptions.find(:first,
        :conditions => { :objekt_type => @context.class.name, :objekt_id => @context.id } )
  end

end
