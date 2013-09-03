# myExperiment: app/controllers/annotations_controller.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'rdf'

include ResearchObjectsHelper

class AnnotationsController < ApplicationController

  def index
    @pack = Pack.find(params[:pack_id])

    @annotations = @pack.research_object.annotations_with_templates
  end 

  def show
    @pack = Pack.find(params[:pack_id])

    @annotation = @pack.research_object.resources.find(:first, :conditions => { :uuid => params[:id] })

    @graph = load_graph(@annotation.ao_body.content_blob.data, :content_type => @annotation.ao_body.content_type)

    @annotation_template, @parameters = @pack.research_object.find_template_from_graph(@graph, Conf.ro_templates)
  end

  def create

    pack = Pack.find(params[:pack_id])

    unless Authorization.check('create', Resource, current_user, pack)
      render_401("You are not authorized to view this resource's relationships.")
      return
    end

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
        pack.research_object.find_using_path(params[parameter["symbol"]]).uri
      end
    end

    targets = template["targets"].map { |t| parameters[t] }

    graph = Pack.first.research_object.create_graph_using_ro_template(parameters, template)

    pack.research_object.create_annotation(
        :body_graph   => graph,
        :content_type => 'application/rdf+xml',
        :resources    => targets,
        :creator_uri  => user_path(current_user))
    
    redirect_to pack_path(pack)
  end

  def destroy

    pack = Pack.find(params[:pack_id])

    annotation = pack.research_object.resources.find_by_uuid(params[:id])

    # Destroy annotation body and also the annotation
    
    annotation.ao_body.destroy
    annotation.destroy

    pack.research_object.update_manifest!

    redirect_to pack_annotations_path(pack)
  end

  def new

    @pack = Pack.find(params[:pack_id])

    @annotation_template = Conf.ro_templates[params[:template]]

    if !@annotation_template
      render_404("Annotation template not found.")
      return
    end
  end

end
