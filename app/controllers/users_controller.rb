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

class UsersController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :new, :create, :search]
  
  before_filter :find_users, :only => [:index]
  before_filter :find_user, :only => [:show]
  before_filter :find_user_auth, :only => [:edit, :update, :destroy]
  
  # GET /users;search
  # GET /users.xml;search
  def search
    @query = params[:query] || ""
    
    @users = User.find_with_ferret(@query)
    
    respond_to do |format|
      format.html # search.rhtml
      format.xml  { render :xml => @users.to_xml }
    end
  end
  
  # GET /users
  # GET /users.xml
  def index
    @users.each do |user|
      user.salt = nil
      user.crypted_password = nil
    end
    
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @users.to_xml }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user.salt = nil
    @user.crypted_password = nil
    
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @user.to_xml }
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1;edit
  def edit
    
  end

  # POST /users
  # POST /users.xml
  def create
    if params[:user][:username] && params[:user][:password] && params[:user][:password_confirmation]
      params[:user].delete("openid_url") if params[:user][:openid_url] # strip params[:user] of it's openid_url if username and password is provided
    end
    
    unless params[:user][:name]
      if params[:user][:username]
        params[:user][:name] = params[:user][:username].humanize # initializes username (if one isn't entered)
      else
        params[:user][:name] = params[:user][:openid_url]
      end
    end
    
    @user = User.new(params[:user])
    
    respond_to do |format|
      if @user.save
        # log user in after succesful create
        #session[:user_id] = @user.id
        self.current_user = @user
        
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to user_url(@user) }
        format.xml  { head :created, :location => user_url(@user) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors.to_xml }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    # openid url's must be validated and updated separately
    params.delete("openid_url") if params[:openid_url]
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to user_url(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors.to_xml }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    flash[:notice] = 'Please contact the administrator to have your account removed.'
    redirect_to :action => :index
    
    #@user.destroy
    
    # the user MUST be logged in to destroy their account
    # it is important to log them out afterwards or they'll 
    # receive a nasty error message..
    #session[:user_id] = nil
    
    #respond_to do |format|
    #  flash[:notice] = 'User was successfully destroyed'
    #  format.html { redirect_to users_url }
    #  format.xml { head :ok }
    #end
  end
  
protected

  def find_users
    @users = User.find(:all, 
                       :order => "name ASC",
                       :page => { :size => 20, 
                                  :current => params[:page] })
  end

  def find_user
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("User not found", "is invalid (not owner)")
    end
  end

  def find_user_auth
    begin
      @user = User.find(params[:id], :conditions => ["id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("User not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private

  def error(notice, message)
    flash[:notice] = notice
    (err = User.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to users_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
