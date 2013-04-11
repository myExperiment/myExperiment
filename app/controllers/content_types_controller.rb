# myExperiment: app/controllers/content_types_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContentTypesController < ApplicationController

  before_filter :find_content_type, :only => [ :show, :edit, :update ]
  before_filter :auth_content_type, :only => [ :edit, :update ]

  # GET /content_types
  def index

    params[:num] = 25 unless params[:num]

    if params[:mime_type]
      @content_types = ContentType.find_all_by_mime_type(params[:mime_type], :order => 'title ASC')
    else
      @content_types = ContentType.find(:all, :order => 'title ASC')
    end

    @content_types = @content_types.paginate(:page => params[:page], :per_page => params[:num])
  end

  # GET /content_types/1
  def show
    @workflow_count = Workflow.count(:conditions => ['content_type_id = ?', @content_type.id])
    @blob_count = Blob.count(:conditions => ['content_type_id = ?', @content_type.id])

    @total_count = @workflow_count + @blob_count

    respond_to do |format|
      format.html {

        @lod_nir  = content_type_url(@content_type)
        @lod_html = content_type_url(:id => @content_type.id, :format => 'html')
        @lod_rdf  = content_type_url(:id => @content_type.id, :format => 'rdf')
        @lod_xml  = content_type_url(:id => @content_type.id, :format => 'xml')

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
      render_404("Content type not found.")
    end
  end

  def auth_content_type
    if !Authorization.check('edit', @content_type, current_user)
      render_401("You are not authorised to edit this content type.")
    end
  end
end
