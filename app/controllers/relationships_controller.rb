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

    subject = @context.find_pack_item(params[:subject])
    objekt  = @context.find_pack_item(params[:objekt])

    prefix, title = params[:predicate].split(":")

    predicate = Predicate.find(:first, :conditions =>
        ['ontology_id = ? AND title = ?',
           Ontology.find_by_prefix(prefix).id, title])

    raise("Invalid form data") if subject.nil? || objekt.nil? || predicate.nil?

    @relationship = Relationship.new(:context => @context, :predicate => predicate, :user => current_user)

    @relationship.subject = subject
    @relationship.objekt  = objekt

    @relationship.save

    redirect_to(:action => :edit_relationships)
  end
  
  # DELETE /:context_type/:context_id/relationships/:id
  def destroy

   if Authorization.is_authorized?('destroy', nil, @relationship, current_user)
      @relationship.destroy
    end
    
    render :partial => "relationships/relationships",
           :locals  => { :context => @context, :show_delete => true }
  end

  private

  def find_resource

    @context      = extract_resource_context(params)
    @relationship = Relationship.find_by_id(params[:id])

    return false if @relationship.nil? || @context.nil? || @relationship.context != @context
    return false if Authorization.is_authorized?('view', nil, @context, current_user) == false
  end

  def find_resource_context

    @context = extract_resource_context(params)

    return false if @context.nil?
    return false if Authorization.is_authorized?('view', nil, @context, current_user) == false
  end

end

