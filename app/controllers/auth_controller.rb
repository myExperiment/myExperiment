class AuthController < ApplicationController
  def login
    begin
      u = User.find(params[:id])
      
      error("Login failed, already logged in", "already logged in") if logged_in?
      
      respond_to do |format|
        session[:user_id] = u.id
          
        flash[:notice] = "#{u.name} has logged in."
        format.html { redirect_to request.env["HTTP_REFERER"] || url_for(:controller => '') }
        format.xml { head :ok }
      end
    rescue ActiveRecord::RecordNotFound
      error("Login failed, user not found (id invalid)", "not found (id invalid)", :id)
    end
  end
  
  def logout
    begin
      u = User.find(params[:id])
      
      if logged_in? and current_user.id.to_i == u.id.to_i
        flash[:notice] = "#{u.name} has logged out."
        session[:user_id] = nil
      
        respond_to do |format|
          format.html { redirect_to request.env["HTTP_REFERER"] || url_for(:controller => '') }
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
    (err = Auth.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to request.env["HTTP_REFERER"] || url_for(:controller => '') }
      format.xml { render :xml => err.to_xml }
    end
  end
end
