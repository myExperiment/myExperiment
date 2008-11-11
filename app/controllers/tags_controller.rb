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
      format.html # show.rhtml
    end
  end
  
  def auto_complete
    text = '';
    
    if params[:tag_list]
      text = params[:tag_list]
    elsif params[:tags_input]
      text = params[:tags_input]
    end
    
    @tags = Tag.find(:all, 
                     :conditions => ["LOWER(name) LIKE ?", text.downcase + '%'], 
                     :order => 'name ASC', 
                     :limit => 20, 
                     :select => 'DISTINCT *')
    render :inline => "<%= auto_complete_result @tags, 'name' %>"
  end
  
protected

  def find_tags
    @tags = Tag.find(:all, :order => "name ASC", :conditions => "taggings_count > 0")
  end
  
  def find_tag_and_tagged_with
    @tag = Tag.find(:first, :conditions => ["id = ?", params[:id]])
    
    if @tag
      @tagged_with = []
      taggings = []
      @internal_type = parse_to_internal_type(params[:type])
      
      if @internal_type
        # Filter by the type
        taggings = Tagging.find(:all, 
                                 :conditions => [ "tag_id = ? AND taggable_type = ?", @tag.id, @internal_type],
                                 :order => "taggable_type DESC") 
      else
        # Get all taggings
        taggings = @tag.taggings
      end
      
      # Authorise entries now
      taggings.each do |t|
        if t.taggable.respond_to?(:contribution)
          @tagged_with << t.taggable if t.taggable.contribution.authorized?("show", current_user)
        else
          @tagged_with << t.taggable
        end
      end
      
      @tagged_with = @tagged_with.uniq
    else
      error("Tag not found", "is invalid")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Tag.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to tags_url }
    end
  end
  
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
