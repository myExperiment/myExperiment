##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

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
    @tags = Tag.find(:all, :order => "name ASC")
  end
  
  def find_tag_and_tagged_with
    begin
      @tag = Tag.find(params[:id])
      
      @tagged_with = []
      @tag.taggings.each do |t|
        c = t.taggable.contribution
        @tagged_with << c if c.authorized?("show", (logged_in? ? current_user : nil))
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
