class PicturesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_pictures, :only => [:index]
  before_filter :find_picture_auth, :only => [:select, :edit, :update, :destroy]
  
  # GET /users/1/pictures/1/select
  # GET /users/1/pictures/1/select.xml
  # GET /pictures/1/select
  # GET /pictures/1/select.xml
  def select
    if @picture.select!
      respond_to do |format|
        flash[:notice] = 'Picture was successfully selected as profile avatar.'
        format.html { redirect_to profile_url(@picture.owner.profile) }
        format.xml  { head :ok }
      end
    else
      error("Picture already selected", "already selected")
    end
  end
  
  # GET /users/1/pictures
  # GET /users/1/pictures.xml
  # GET /pictures
  # GET /pictures.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @pictures.to_xml }
    end
  end

  # GET /users/1/pictures/1
  # GET /pictures/1
  flex_image :action => 'show', :class => Picture

  # GET /users/1/pictures/new
  # GET /pictures/new
  def new
    @picture = Picture.new
  end

  # GET /users/1/pictures/1;edit
  # GET /pictures/1;edit
  def edit
    
  end

  # POST /users/1/pictures
  # POST /users/1/pictures.xml
  # POST /pictures
  # POST /pictures.xml
  def create
    @picture = Picture.create(:data => params[:picture][:data])
    @picture.user_id = current_user.id

    respond_to do |format|
      if @picture.save
        flash[:notice] = 'Picture was successfully created.'
        format.html { redirect_to pictures_url(@picture.user_id) }
        format.xml  { head :created, :location => picture_url(@picture.user_id, @picture) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @picture.errors.to_xml }
      end
    end
  end

  # PUT /users/1/pictures/1
  # PUT /users/1/pictures/1.xml
  # PUT /pictures/1
  # PUT /pictures/1.xml
  def update
    respond_to do |format|
      if @picture.update_attributes(params[:picture])
        flash[:notice] = 'Picture was successfully updated.'
        format.html { redirect_to pictures_url(@picture.user_id) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @picture.errors.to_xml }
      end
    end
  end

  # DELETE /users/1/pictures/1
  # DELETE /users/1/pictures/1.xml
  # DELETE /pictures/1
  # DELETE /pictures/1.xml
  def destroy
    user_id = @picture.user_id
    
    @picture.destroy

    respond_to do |format|
      format.html { redirect_to pictures_url(user_id) }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_pictures
    if params[:user_id]
      @pictures = Picture.find(:all, :conditions => ["user_id = ?", params[:user_id]])
    else
      @pictures = Picture.find(:all)
    end
  end

  def find_picture_auth
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
