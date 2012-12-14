require 'wf4ever/rosrs_client'
require 'helpers/folders_helper'

class FoldersController < ApplicationController
  
  include FoldersHelper
  
  def index
    if params[:ro_uri].blank?
      render :text => "Please supply an RO URI."
    end
    # Renders folder.html.erb
  end

  # Get a folder's contents when it is expanded in the UI
  def folder_contents
    ro = make_research_object(params[:ro_uri])
    folder = ROSRS::Folder.new(ro, params[:folder_uri])
    @contents = folder.contents.map {|fe| [fe.resource.uri, fe.name]}
    respond_to do |format|
      format.js { render :json => @contents }
    end
    # Renders folder_contents.js.erb
   end

end
