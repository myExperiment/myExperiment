class AuthController < ApplicationController
  def login(user_id = 1)
    flash[:notice] = "#{User.find(user_id).name} has logged in."
    session[:user_id] = user_id
    
    respond_to do |format|
      format.html { redirect_to :controller => 'users' }
      format.xml { head :ok }
    end
  end
  
  def logout(user_id = 1)
    flash[:notice] = "#{User.find(user_id).name} has logged out."
    session[:user_id] = nil
      
    respond_to do |format|
      format.html { redirect_to :controller => 'users' }
      format.xml { head :ok }
    end
  end
end
