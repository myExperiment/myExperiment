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

class PicturesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_pictures, :only => [:index]
  before_filter :find_picture, :only => [:show]
  before_filter :find_picture_auth, :only => [:select, :edit, :update, :destroy]
  
  # GET /users/1/pictures/1/select
  # GET /users/1/pictures/1/select.xml
  # GET /pictures/1/select
  # GET /pictures/1/select.xml
  def select
    if @picture.select!
      # create and save picture selection record
      PictureSelection.create(:user => current_user, :picture => @picture)
      
      respond_to do |format|
        flash[:notice] = 'Picture was successfully selected as profile avatar.'
        format.html { redirect_to pictures_url(@picture.owner) }
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
  def show
    size = params[:size] || "200x200"
    size = size[0..-($1.length.to_i + 2)] if size =~ /[0-9]+x[0-9]+\.([a-z0-9]+)/ # trim file extension
    
    if cache_exists?(@picture, size) # look in file system cache before attempting db access
      send_file(full_cache_path(@picture, size), :type => 'image/jpeg', :disposition => 'inline')
    else
      # resize and encode the picture
      @picture.resize!(:size => size)
      @picture.to_jpg!
      
      # cache data
      cache_data!(@picture, size)
      
      send_data(@picture.data, :type => 'image/jpeg', :disposition => 'inline')
    end
  end
  
  #flex_image :action => :show, 
  #           :class => Picture, 
  #           :padding => true
  
  # adding this line 'should' cache the show method within Mongrel/WebBrick
  # caches_page :show

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
    @picture = Picture.create(:data => params[:picture][:data], :user_id => current_user.id)

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
    elsif logged_in?
      redirect_to pictures_url(current_user)
    else
      error("Please supply a User ID", "not supplied", :user_id)
    end
  end
  
  def find_picture
    if params[:id]
      if picture = Picture.find(:first, :conditions => ["id = ?", params[:id]])
        @picture = picture
      else
        error("Picture not found (id not found)", "is invalid (not found)")
      end
    else
      error("Please supply an ID", "not supplied")
    end
  end

  def find_picture_auth
    if params[:user_id]
      begin
        @picture = Picture.find(params[:id], :conditions => ["user_id = ?", params[:user_id]])
      rescue ActiveRecord::RecordNotFound
        error("Picture not found (id not authorized)", "is invalid (not owner)")
      end
    else
      error("Please supply a User ID", "not supplied", :user_id)
    end
  end

private
  
  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Picture.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to logged_in? ? pictures_url(current_user) : '' }
      format.xml { render :xml => err.to_xml }
    end
  end
  
  # returns true if /pictures/show/:id?size=#{size}x#{size} is cached in file system
  def cache_exists?(picture, size=nil)
    File.exists?(full_cache_path(picture, size))
  end
  
  # caches data (where size = #{size}x#{size})
  def cache_data!(picture, size=nil)
    FileUtils.mkdir_p(cache_path(picture, size))
    File.open(full_cache_path(picture, size), "wb+") { |f| f.write(picture.data) }
  end
  
  def cache_path(picture, size=nil, include_local_name=false)
    rtn = "#{RAILS_ROOT}/public/pictures/show"
    rtn = "#{rtn}/#{size}" if size
    rtn = "#{rtn}/#{picture.id}.jpg" if include_local_name
    
    return rtn
  end
  
  def full_cache_path(picture, size=nil) 
    cache_path(picture, size, true) 
  end
end
