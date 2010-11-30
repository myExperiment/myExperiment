# myExperiment: app/controllers/content_types_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContentTypesController < ApplicationController

  before_filter :find_content_type, :only => [ :show, :edit, :update ]

  # GET /content_types
  def index

    params[:num] = 25 unless params[:num]

    @content_types = ContentType.find(:all, :order => 'title ASC',
        :page => { :size => params[:num], :current => params[:page] })
  end

  # GET /content_types/1
  def show
    @workflow_count = Workflow.count(:conditions => ['content_type_id = ?', @content_type.id])
    @blob_count = Blob.count(:conditions => ['content_type_id = ?', @content_type.id])

    @total_count = @workflow_count + @blob_count

    respond_to do |format|
      format.html {

        @lod_nir  = content_type_url(@content_type)
        @lod_html = formatted_content_type_url(:id => @content_type.id, :format => 'html')
        @lod_rdf  = formatted_content_type_url(:id => @content_type.id, :format => 'rdf')
        @lod_xml  = formatted_content_type_url(:id => @content_type.id, :format => 'xml')

        # show.rhtml
      }


      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} content_types #{@content_type.id}`
        }
      end
    end
  end

  # GET /content_types/1
  def edit
  end

  # PUT /content_types/1
  def update

    if !Authorization.check(:action => 'edit', :object => @content_type, :user => current_user)
      error("You do not have the authorisation to edit.", "is unauthorised")
      return
    end

    @content_type.title       = params[:content_type][:title]
    @content_type.description = params[:content_type][:description]

    if @content_type.valid?
      @content_type.save
      redirect_to :action => 'show'
    else
      flash[:error] = "Failed to update Content Type."
      render :action => :edit
    end
  end

  private

  def find_content_type
    @content_type = ContentType.find_by_id(params[:id])

    if @content_type.nil?
      error("Content type not found", "is invalid")
      return false
    end
  end

  def error(notice, message, attr=:id)
    flash[:error] = notice
     (err = ContentType.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to content_types_url }
    end
  end
end

