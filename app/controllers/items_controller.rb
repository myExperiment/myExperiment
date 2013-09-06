# myExperiment: app/controllers/items_controller.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class ItemsController < ApplicationController

  include ResearchObjectsHelper

  before_filter :find_and_auth_resource_context
  before_filter :find_item

  def index
    show
  end

  def show

    @annotations = @item.annotations_with_templates

    @visible_annotations = @annotations.select { |a| a[:template] != nil }

    @statements = merge_graphs(@annotations.map { |annotation| annotation[:graph] })

    unless @item.is_folder
      @title = @statements.query([@item.uri, RDF::DC.title, nil]).first_value || @item.folder_entry.entry_name
      @description = @statements.query([@item.uri, RDF::DC.description, nil]).first_value
      @input_files_for_this_workflow = @statements.query([@item.uri, RDF::URI("http://purl.org/wf4ever/roterms#inputSelected"), nil]).objects
      @requires_hardware = @statements.query([@item.uri, RDF::URI("http://purl.org/wf4ever/roterms#requiresHardware"), nil]).objects
      @requires_software = @statements.query([@item.uri, RDF::URI("http://purl.org/wf4ever/roterms#requiresSoftware"), nil]).objects
      @roles_in_time = @statements.query([nil, RDF::URI("http://purl.org/spar/pro/relatesToEntity"), @item.uri]).subjects
    end

    if @item.is_folder
      render :action => 'folder_show'
    end
  end

  def destroy

    unless Authorization.check('destroy', @item, current_user)
      render_401("You are not authorized to delete this item.")
      return
    end

    # Delete the resource context if it exists.
    @item.context.destroy if @item.context

    # Delete the resource
    @item.destroy

    redirect_to @context
  end

private

  def find_and_auth_resource_context
    @context = extract_resource_context(params)

    if @context.nil?
      render_404("Item context not found.")
    elsif !Authorization.check('view', @context, current_user)
      render_401("You are not authorized to view the items of this resource.")
    end
  end

  def find_item

    if params[:action] == 'index'
      @item = @context.research_object.root_folder
    else
      @item = @context.research_object.find_using_path(params[:id])
    end

    if @item.nil?
      render_404("Relationship not found.")
    end
  end
end
