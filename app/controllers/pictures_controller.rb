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

  before_filter :login_required

  def index
    list
    render :action => 'list'
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :action => :list }
  
  def list
    @user = User.find(session[:user_id])
    @pictures = Picture.find_all_by_user_id(session[:user_id])
  end
  
  def select
    if params[:id]
      @user = User.find(session[:user_id]);
      picture = Picture.find(params[:id])
      if picture.user_id == nil or picture.user_id == @user.id
        @user.avatar = params[:id]
        
        if @user.save
          flash[:notice] = 'Picture was successfully updated.'
          redirect_to :controller => 'profile', :action => 'index'
        else
          redirect_to :action => 'list'
        end
      else
        redirect_to :action => 'list'
      end
    else
      @user.avatar = Picture.find_by_user_id(@user.id)
      
      if @user.save
        flash[:notice] = 'Picture was successfully removed.'
        redirect_to :controller => 'profile', :action => 'index'
      end
    end
  end
  
  flex_image :action => 'show',  :class => Picture
  
  def new
    @picture = Picture.new
  end
  
  def create
    if params[:picture] and params[:picture][:data] and not params[:picture][:data].blank?
      @picture = Picture.create(:data => params[:picture][:data])
      if @picture.data
        @picture.user_id = session[:user_id]
        if @picture.save
          flash[:notice] = 'Picture was successfully created.'
          #        redirect_to :action => 'list'
          render :action => 'crop'
        else
          render :action => 'new'
        end
      else
        flash[:notice] = 'No picture was uploaded. Please try again.'
        render :action => 'new'
      end
    else
      flash[:notice] = 'Please select an image to upload.'
      render :action => 'new'
    end
  end
  
  def crop
    @picture = Picture.find(params[:id])
    if @picture
      if params[:cancel]
        flash[:notice] = "Cropping canceled."
        redirect_to :action => 'list'
      else
        # cancel was not clicked, so crop the image
        @picture.krop! params
        if @picture.save
          flash[:notice] = "Image cropped and saved successfully."
          redirect_to :action => 'list'
        end
      end
    else
      flash[:error] = "Nothing to crop."
      redirect_to :action => 'new'
    end
  rescue Picture::InvalidCropRect
    flash[:error] = "Sorry, could not crop the image."
  end
  
  def edit
    @picture = Picture.find(params[:id])
  end
  
  def update
    @picture = Picture.find(params[:id])
    if @picture.update_attributes(params[:picture])
      flash[:notice] = 'Picture was successfully updated.'
      redirect_to :action => 'show', :id => @picture
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    Picture.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
