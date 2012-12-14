require 'wf4ever/rosrs_client'

class FoldersController < ApplicationController

  BASE_URI = "http://sandbox.wf4ever-project.org/rodl/ROs/"
  API_KEY = "32801fc0-1df1-4e34-b"
  
  def index
    @structure = {}
    if params[:ro_uri].blank?
      render :text => "Please supply an RO URI."
    else
      @session = ROSRS::Session.new(BASE_URI, API_KEY)
      @ro = ROSRS::ResearchObject.new(@session, params[:ro_uri])
      @structure = {:label => @ro.root_folder.name,
                    :labelStyle => "root_folder",
                    :uri => @ro.root_folder.uri}
      @resources = {}
      (@ro.resources + @ro.folders).each do |res|
        type = 'folder'
        leaf = false
        unless res.is_a?(ROSRS::Folder)
          type = 'resource'
          leaf = true
        end
        @resources[res.uri] = {:labelStyle => type, :uri => res.uri, :isLeaf => leaf}
      end
    end
    # Renders folder.html.erb
  end

  # Get a folder's contents when it is expanded in the UI
  def folder_contents
    @session = ROSRS::Session.new(BASE_URI, API_KEY)
    @ro = ROSRS::ResearchObject.new(@session, params[:ro_uri])
    folder = ROSRS::Folder.new(@ro, params[:folder_uri])
    @contents = folder.contents.map {|fe| [fe.resource.uri, fe.name]}
    respond_to do |format|
      format.js { render :json => @contents }
    end
    # Renders folder_contents.js.erb
   end

end
