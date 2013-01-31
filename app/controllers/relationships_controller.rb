# myExperiment: app/controllers/relationships_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class RelationshipsController < ApplicationController
  
  helper PacksHelper

  before_filter :find_resource_context
  before_filter :find_resource, :except => [ :edit_relationships, :create ]

  # GET /:context_type/:context_id/edit_relationships
  def edit_relationships

    @predicates = Ontology.find(:all).map do |o| o.predicates end.flatten

    @pack_entries = @context.contributable_entries + @context.remote_entries

    @select_options = @pack_entries.map do |pe|
      if pe.class == PackContributableEntry
        [pe.contributable.label, "contributable:#{pe.id}"]
      else
        [pe.title, "remote:#{pe.id}"]
      end
    end
  end

  # POST /:context_type/:context_id/relationships
  def create 

    subject_name = URI::decode(params[:subject])
    object_name  = URI::decode(params[:object])

    subject = @context.contributable_entries.find_by_name(subject_name)
    object  = @context.contributable_entries.find_by_name(object_name)

    match = params[:predicate].match("(.*[#/])([^#/]+)")

    ns1  = match[1]
    prop = match[2]

    session = ROSRS::Session.new(@context.ro_uri, Conf.rodl_bearer_token)

    subject_uri = "#{@context.ro_uri}#{URI::encode(subject.name)}"
    object_uri  = "#{@context.ro_uri}#{URI::encode(object.name)}"

    ao_body = <<RDF
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:ns1="#{ns1}" >
  <rdf:Description rdf:about="#{subject_uri}">
    <ns1:#{prop} rdf:resource="#{object_uri}"/>
  </rdf:Description>
</rdf:RDF>
RDF

    agraph = ROSRS::RDFGraph.new(:data => ao_body, :format => :xml)

    begin
      code, reason, stub_uri, body_uri = session.create_internal_annotation(@context.ro_uri, subject_uri, agraph)
      code, reason, stub_uri, body_uri = session.create_internal_annotation(@context.ro_uri, object_uri,  agraph)
    rescue ROSRS::Exception => e
      errors.add(params[:template], 'Error from remote server')
    end

    flash[:notice] = "Relationship added."
    redirect_to pack_path(@context.id)
  end
  
  # DELETE /:context_type/:context_id/relationships/:id
  def destroy

   if Authorization.check('destroy', @relationship, current_user)
      @relationship.destroy
    end
    
    render :partial => "relationships/relationships",
           :locals  => { :context => @context, :show_delete => true }
  end

  private

  def find_resource

    @context      = extract_resource_context(params)

    return nil if @context.ro_uri

    @relationship = Relationship.find_by_id(params[:id])

    return error if @relationship.nil? || @context.nil? || @relationship.context != @context
    return error if Authorization.check('view', @context, current_user) == false
  end

  def find_resource_context

    @context = extract_resource_context(params)

    return false if @context.nil?
    return false if Authorization.check('view', @context, current_user) == false
  end

  def error
    render :text => 'Error.'
  end
end

