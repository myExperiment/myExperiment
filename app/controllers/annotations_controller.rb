# myExperiment: app/controllers/annotations_controller.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'rdf'

include ResearchObjectsHelper

class AnnotationsController < ApplicationController

  before_filter :find_and_auth_resource_context

  def index
    @annotations = @context.research_object.all_annotations_with_templates
  end 

  def show
    @annotation = @context.research_object.resources.find(:first, :conditions => { :uuid => params[:id] })

    @graph = load_graph(@annotation.ao_body.content_blob.data, :content_type => @annotation.ao_body.content_type)

    @annotation = @context.research_object.annotation_with_template(@annotation)
  end

  def create

    template = Conf.ro_templates[params[:annotation_type]]

    if template.nil?
      render_500("Unknown annotation type")
      return
    end

    parameters = {}

    template["parameters"].each do |parameter|

      parameters[parameter["symbol"]] = case parameter["type"]

      when "string", "textarea"
        RDF::Literal(params[parameter["symbol"]])
      when "select"
        case parameter["node_type"]
        when "literal"
          RDF::Literal(params[parameter["symbol"]])
        when "resource"
          RDF::URI(params[parameter["symbol"]])
        end
      when "resource"
        @context.research_object.find_using_path(params[parameter["symbol"]]).uri
      end
    end

    targets = template["targets"].map { |t| parameters[t] }

    graph = Pack.first.research_object.create_graph_using_ro_template(parameters, template)

    annotation = @context.research_object.create_annotation(
        :body_graph   => graph,
        :content_type => 'application/rdf+xml',
        :resources    => targets,
        :creator_uri  => user_path(current_user))

    unless annotation.new_record?
      Activity.create_activities(:subject => current_user, :action => 'create', :object => annotation, :extra => template["label"])
    end

    if template["redirect"]
      redirect_to resource_path_fixed(@context, @context.find_resource_by_ore_path(params[template["redirect"]]))
    else
      redirect_to polymorphic_path(@context)
    end
  end

  def destroy

    annotation = @context.research_object.resources.find_by_uuid(params[:id])

    # Destroy annotation body and also the annotation
    
    annotation.ao_body.destroy
    annotation.destroy

    @context.research_object.update_manifest!

    if params[:source]
      redirect_to resource_path_fixed(@context, @context.find_resource_by_ore_path(params[:source]))
    else
      redirect_to polymorphic_path([@context, :annotations])
    end
  end

  def new

    @annotation_template = Conf.ro_templates[params[:template]]

    if !@annotation_template
      render_404("Annotation template not found.")
      return
    end
  end

private

  def find_and_auth_resource_context
    @context = extract_resource_context(params)

    if @context.nil?
      render_404("Annotation context not found.")
    elsif !Authorization.check('view', @context, current_user)
      render_401("You are not authorized to view the annotations of this resource.")
    end
  end

end
