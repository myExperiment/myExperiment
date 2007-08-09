class BlobsController < ApplicationController
  before_filter :authorize, :except => [:index, :show, :download]
  
  before_filter :find_blobs, :only => [:index]
  before_filter :find_blob, :only => [:show]
  before_filter :find_blob_auth, :only => [:download, :edit, :update, :destroy]
  
  # GET /blobs/1;download
  def download
    if @blob.authorized?("download", (logged_in? ? current_user : nil))
      send_data(@blob.data, :filename => @blob.local_name, :type => @blob.content_type)
    else
      flash[:notice] = "Not authorized to download #{@blob.local_name}"
      redirect_to 'index'
    end
    
    #send_file("#{RAILS_ROOT}/#{controller_name}/#{@blob.contributor_type.downcase.pluralize}/#{@blob.contributor_id}/#{@blob.local_name}", :filename => @blob.local_name, :type => @blob.content_type)
  end
  
  # GET /blobs
  # GET /blobs.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @blobs.to_xml }
    end
  end

  # GET /blobs/1
  # GET /blobs/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @blob.to_xml }
    end
  end

  # GET /blobs/new
  def new
    @blob = Blob.new
  end

  # GET /blobs/1;edit
  def edit

  end

  # POST /blobs
  # POST /blobs.xml
  def create
    params[:blob][:local_name] = params[:blob][:data].original_filename
    params[:blob][:content_type] = params[:blob][:data].content_type
    params[:blob][:data] = params[:blob][:data].read
    
    @blob = Blob.new(params[:blob])

    respond_to do |format|
      if @blob.save
        flash[:notice] = 'Blob was successfully created.'
        format.html { redirect_to blob_url(@blob) }
        format.xml  { head :created, :location => blob_url(@blob) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @blob.errors.to_xml }
      end
    end
  end

  # PUT /blobs/1
  # PUT /blobs/1.xml
  def update
    respond_to do |format|
      if @blob.update_attributes(params[:blob])
        flash[:notice] = 'Blob was successfully updated.'
        format.html { redirect_to blob_url(@blob) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blob.errors.to_xml }
      end
    end
  end

  # DELETE /blobs/1
  # DELETE /blobs/1.xml
  def destroy
    @blob.destroy

    respond_to do |format|
      format.html { redirect_to blobs_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_blobs
    @blobs = Blob.find(:all, :order => "local_name ASC")
  end
  
  def find_blob
    begin
      @blob = Blob.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("Blob not found", "is invalid")
    end
  end
  
  def find_blob_auth
    begin
      blob = Blob.find(params[:id])
      
      if blob.authorized?(action_name, (logged_in? ? current_user : nil))
        @blob = blob
      else
        error("Blob not found (id not authorized)", "is invalid (not authorized)")
      end
    rescue ActiveRecord::RecordNotFound
      error("Blob not found", "is invalid")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Blob.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to blobs_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
