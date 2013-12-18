# myExperiment: app/controllers/items_controller.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class ItemsController < ApplicationController

  include ResearchObjectsHelper

  before_filter :find_and_auth_resource_context
  before_filter :find_item

  def index
    respond_to do |format|

      format.html {
        show
      }

      format.rss {
        if params[:pack_id]
          @pack = Pack.find(params[:pack_id])
          if Authorization.check('view', @pack, current_user)
            render :action => 'items.rxml', :layout => false
          end
        end
      }
    end
  end

  def show

    @annotations = @item.annotations_with_templates

    @visible_annotations = @annotations.select { |a| a[:template] != nil }

    @statements = merge_graphs(@annotations.map { |annotation| annotation[:graph] })

    @item_uri = @item.uri
    @view_uri = RDF::URI(params[:resource]) if params[:resource]

    @wsdl_uris = @statements.query([nil, RDF::URI("http://purl.org/wf4ever/wf4ever#wsdlURI"), nil]).map { |s, p, o| o }

    # Show a custom view if a view parameter is given

    if @view_uri
      @view_types = @statements.query([@view_uri, RDF.type, nil]).objects

      @resource_uri = polymorphic_path([@context, :items]) + "/" + @item.ore_path
      @view_uri = RDF::URI(params[:resource])

      if @view_types.include?(RDF::URI("http://purl.org/wf4ever/wfprov#WorkflowRun"))
        render :workflow_run
        return
      elsif @view_types.include?(RDF::URI("http://purl.org/wf4ever/wfprov#ProcessRun"))
        render :process_run
        return
      else
        if Rails.env == "development"
          render(:partial => "debug", :locals => { :item => @item, :view_uri => @view_uri, :statements => @statements }, :layout => true)
          return
        end
      end
    end

    unless @item.is_folder
      @title = @statements.query([@item_uri, RDF::DC.title, nil]).first_value || @item.folder_entry.entry_name
      @description = @statements.query([@item_uri, RDF::DC.description, nil]).first_value
      @input_files_for_this_workflow = @statements.query([@item_uri, RDF::URI("http://purl.org/wf4ever/roterms#inputSelected"), nil]).objects
      @requires_hardware = @statements.query([@item_uri, RDF::URI("http://purl.org/wf4ever/roterms#requiresHardware"), nil]).objects
      @requires_software = @statements.query([@item_uri, RDF::URI("http://purl.org/wf4ever/roterms#requiresSoftware"), nil]).objects
      @roles_in_time = @statements.query([nil, RDF::URI("http://purl.org/spar/pro/relatesToEntity"), @item_uri]).subjects

      # Get the top-level workflow runs by selecting only those that were not
      # part of other workflow runs.

      @workflow_runs = @statements.query([nil, RDF.type, RDF::URI("http://purl.org/wf4ever/wfprov#WorkflowRun")]).subjects.to_a
      @workflow_runs -= @statements.query([nil, RDF::URI("http://purl.org/wf4ever/wfprov#wasPartOfWorkflowRun"), nil]).subjects.to_a
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
    Activity.create_activities(:subject => current_user, :action => 'destroy', :object => @item)

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

  def ro_uri
      if @context.research_object
          return @context.research_object.uri
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
