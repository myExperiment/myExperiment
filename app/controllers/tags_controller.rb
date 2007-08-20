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
  
protected

  def find_tags
    @tags = Tag.find(:all, :order => "name")
  end
  
  def find_tag_and_tagged_with
    begin
      @tag = Tag.find(params[:id])
      
      @tagged_with = []
      
      Contribution.find(:all, :select => "contributable_type", :group => "contributable_type").each do |c|
        @tagged_with << c.contributable_type.classify.constantize.find_tagged_with(@tag.name)
      end
      
      @tagged_with.flatten!
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
