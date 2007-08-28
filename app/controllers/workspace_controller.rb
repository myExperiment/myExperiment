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

require 'open-uri'
require "rexml/document"

class WorkspaceController < ApplicationController

  def index
    @workflows = @user.workflows.find(:all, :page => {:size => 10, :current => params[:workflowspage], :first => 1}) if @user
    @bookmarks = Workflow.find_bookmarked_by_user(@user, :page => {:size => 2, :current => params[:bookmarkspage], :first => 1}) if @user
  end
  
  def addworkflow
  
    @workflow = params[:id]
  
    redirect_to :action => 'index'
  
  end

  def import
  end

  def upload
    url = URI.parse(params[:import][:url])
    document = REXML::Document.new(url.read)
    root = document.root
    #raise "Doesn't appear to be a workflow!" if root.name != "scufl"
    elements = 0
    root.each_element('workflow') { |workflow|
                                     workflow_url = URI.parse(workflow.attribute('url').to_s)
                                     create workflow_url
                                     elements += 1
                                  }
    flash[:notice] = "Uploaded #{elements} workflows"
    redirect_to :action => 'index'
  end

  def create(scufl)    
    scuflFile = StringIO.new(scufl.read)
    scuflFile.extend FileUpload

    scuflFile.original_filename = "workflow.xml"
    scuflFile.content_type = "text/xml"
    
    workflow = { :scufl => scuflFile }
    parser = Scufl::Parser.new
    scufl_model = parser.parse(workflow[:scufl].read)
    
    workflow[:scufl].rewind
    
    workflow[:image] = get_image(scufl_model, workflow[:scufl].original_filename)
    workflow[:title] = scufl_model.description.title
    workflow[:description] = scufl_model.description.description
    
    @workflow = Workflow.new(workflow)
    @workflow.user_id = session[:user_id]
    @workflow.save
  end
   
  def get_image(model, filename)
    dot = Scufl::Dot.new
    
    # create temp file
    tmpDotFile = Tempfile.new("image")
    
    # write dot to temp file
    dot.write_dot(tmpDotFile, model)
    tmpDotFile.close
    
    # call out to dot to create the image
    img = StringIO.new(`dot -Tpng #{tmpDotFile.path}`)
                       
    # delete the temporary file
    tmpDotFile.delete
                       
    img.extend FileUpload
                       
    if filename
      img.original_filename = filename.split('.')[0] + ".png"
    else
      img.original_filename = "workflow.png"
    end
    img.content_type = "image/png"
    
    return img
  end

end

module FileUpload
  attr_accessor :original_filename, :content_type
end

