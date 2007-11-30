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
      format.xml  { render :xml => @tags.to_xml }
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @tag.to_xml }
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
    begin
      @tag = Tag.find(params[:id])
      
      @tagged_with = []
      @tag.taggings.each do |t|
        i = t.taggable
        @tagged_with << i if (["network"].include?(t.taggable_type.downcase) ? true : i.contribution.authorized?("show", (logged_in? ? current_user : nil)))
      end
    rescue ActiveRecord::RecordNotFound
      error("Tag not found", "is invalid")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Tag.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to tags_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
