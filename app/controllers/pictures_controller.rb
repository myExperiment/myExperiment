class PicturesController < ApplicationController
  # GET /pictures
  # GET /pictures.xml
  def index
    @pictures = Picture.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @pictures.to_xml }
    end
  end

  # GET /pictures/1
  # GET /pictures/1.xml
  def show
    @picture = Picture.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @picture.to_xml }
    end
  end

  # GET /pictures/new
  def new
    @picture = Picture.new
  end

  # GET /pictures/1;edit
  def edit
    @picture = Picture.find(params[:id])
  end

  # POST /pictures
  # POST /pictures.xml
  def create
    @picture = Picture.new(params[:picture])

    respond_to do |format|
      if @picture.save
        flash[:notice] = 'Picture was successfully created.'
        format.html { redirect_to picture_url(@picture) }
        format.xml  { head :created, :location => picture_url(@picture) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @picture.errors.to_xml }
      end
    end
  end

  # PUT /pictures/1
  # PUT /pictures/1.xml
  def update
    @picture = Picture.find(params[:id])

    respond_to do |format|
      if @picture.update_attributes(params[:picture])
        flash[:notice] = 'Picture was successfully updated.'
        format.html { redirect_to picture_url(@picture) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @picture.errors.to_xml }
      end
    end
  end

  # DELETE /pictures/1
  # DELETE /pictures/1.xml
  def destroy
    @picture = Picture.find(params[:id])
    @picture.destroy

    respond_to do |format|
      format.html { redirect_to pictures_url }
      format.xml  { head :ok }
    end
  end
end
