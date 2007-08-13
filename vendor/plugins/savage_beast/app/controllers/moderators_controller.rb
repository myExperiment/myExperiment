class ModeratorsController < ApplicationController
  def destroy
    Moderatorship.delete_all ['id = ?', params[:id]]
    redirect_to user_path(params[:user_id])
  end

  #overide in your app
  def authorized?
  end
end
