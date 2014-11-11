# encoding: utf-8
# myExperiment: app/controllers/tags_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class TagsController < ApplicationController
  before_filter :find_tags, :only => [:index]
  before_filter :find_tag_and_tagged_with, :only => [:show]
  
  helper ActsAsTaggableHelper
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  def show
    respond_to do |format|
      format.html {

        @lod_nir  = tag_url(@tag)
        @lod_html = tag_url(:id => @tag.id, :format => 'html')
        @lod_rdf  = tag_url(:id => @tag.id, :format => 'rdf')
        @lod_xml  = tag_url(:id => @tag.id, :format => 'xml')

        # show.rhtml
      }

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} tags #{@tag.id}`
        }
      end
    end
  end
  
  def auto_complete
    text = '';
    
    if params[:tag_list]
      text = params[:tag_list]
    elsif params[:tags_input]
      text = params[:tags_input]
    end
    
    @tags = ActsAsTaggableOn::Tag.find(:all,
                     :conditions => ["LOWER(name) LIKE ?", text.downcase + '%'], 
                     :order => 'name ASC', 
                     :limit => 20, 
                     :select => 'DISTINCT *')
    render :inline => "<%= auto_complete_result @tags, 'name' %>"
  end
  
protected

  def find_tags
    @tags = ActsAsTaggableOn::Tag.find(:all, :order => "name ASC", :conditions => "taggings_count > 0")
  end
  
  def find_tag_and_tagged_with
    @tag = ActsAsTaggableOn::Tag.find_by_id(params[:id])
    
    if @tag
      @tagged_with = []
      taggings = []
      @internal_type = parse_to_internal_type(params[:type])
      
      if @internal_type
        # Filter by the type
        taggings = ActsAsTaggableOn::Tagging.find(:all,
                                 :conditions => [ "tag_id = ? AND taggable_type = ?", @tag.id, @internal_type],
                                 :order => "taggable_type DESC") 
      else
        # Get all taggings
        taggings = @tag.taggings
      end
      
      # Authorise entries now
      taggings.each do |t|
        if t.taggable.respond_to?(:contribution)
          @tagged_with << t.taggable if Authorization.check('view', t.taggable.contribution, current_user)
        else
          @tagged_with << t.taggable
        end
      end
      
      @tagged_with = @tagged_with.uniq
    else
      render_404("Tag not found.")
    end
  end
  
private

  # This needs to be refactored into a library somewhere!
  # (eg: a myExperiment system library)
  def parse_to_internal_type(type)
    return nil if type.blank? or type.downcase == "all"
    
    case type.downcase.singularize
      when 'workflow'; return 'Workflow'
      when 'file';     return 'Blob'
      when 'group';    return 'Network'
    end
  end
end
