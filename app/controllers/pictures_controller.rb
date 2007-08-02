class PicturesController < ApplicationController
  before_filter :authorize, :except => [:index, :show]
  
  before_filter :find_picture, :only => [:edit, :update, :destroy]
  
  # GET /pictures
  # GET /pictures.xml
  def index
    if params[:user_id]
      @pictures = Picture.find(:all, :conditions => ["user_id = ?", params[:user_id]])
    else
      @pictures = Picture.find(:all)
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @pictures.to_xml }
    end
  end

  # GET /pictures/1
  # GET /pictures/1.xml
  flex_image :action => 'show', :class => Picture
  # def show
  #   @picture = Picture.find(params[:id])
  #
  #   respond_to do |format|
  #     format.html # show.rhtml
  #     format.xml  { render :xml => @picture.to_xml }
  #   end
  # end

  # GET /pictures/new
  def new
    @picture = Picture.new
  end

  # GET /pictures/1;edit
  def edit
    
  end

  # POST /pictures
  # POST /pictures.xml
  def create
    @picture = Picture.create(:data => params[:picture][:data])
    @picture.user_id = current_user.id

    respond_to do |format|
      if @picture.save
        flash[:notice] = 'Picture was successfully created.'
        format.html { redirect_to pictures_url(current_user.id) }
        format.xml  { head :created, :location => picture_url(@picture.user_id, @picture) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @picture.errors.to_xml }
      end
    end
  end

  # PUT /pictures/1
  # PUT /pictures/1.xml
  def update
    respond_to do |format|
      if @picture.update_attributes(params[:picture])
        flash[:notice] = 'Picture was successfully updated.'
        format.html { redirect_to pictures_url(current_user.id) }
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
    @picture.destroy

    respond_to do |format|
      format.html { redirect_to pictures_url(current_user.id) }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_picture
    begin
      @picture = Picture.find(params[:id], :conditions => ["user_id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("Picture not found (id not authorized)", "is invalid (not owner)")
    end
  end

private
  
  def error(notice, message)
    flash[:notice] = notice
    (err = Picture.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to pictures_url(current_user.id) }
      format.xml { render :xml => err.to_xml }
    end
  end
end
