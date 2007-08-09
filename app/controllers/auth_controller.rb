class AuthController < ApplicationController
  def login
    begin
      u = User.find(params[:id])
      
      if logged_in?
        if current_user.id.to_i == u.id.to_i
          error("Login failed, already logged in", "already logged in")
        else
          error("Login failed, please log out first", "log out first")
        end
      else
        session[:user_id] = u.id
        flash[:notice] = "#{u.name} has logged in."
          
        respond_to do |format|
          format.html { redirect_to users_url }
          format.xml { head :ok }
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Login failed, user not found (id invalid)", "not found (id invalid)")
    end
  end
  
  def logout
    begin
      u = User.find(params[:id])
      
      if logged_in? and current_user.id.to_i == u.id.to_i
        flash[:notice] = "#{u.name} has logged out."
        session[:user_id] = nil
      
        respond_to do |format|
          format.html { redirect_to users_url }
          format.xml { head :ok }
        end
      else
        error("Logout failed, not logged in", "not logged in")
      end
    rescue ActiveRecord::RecordNotFound
      error("Logout failed, user not found (id invalid)", "not found (id invalid)")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = User.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to users_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
