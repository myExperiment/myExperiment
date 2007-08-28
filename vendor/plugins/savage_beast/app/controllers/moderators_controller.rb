class ModeratorsController < ApplicationController
  before_filter :login_required
  
  def destroy
    if authorized?
      Moderatorship.find_by_forum_id_and_user_id(params[:id], params[:user_id]).destroy
    else
      flash[:notice] = "You are not authorized to edit this forum!"
    end
    
    redirect_to :action => :list, :id => params[:id]
  end
  
  def create
    if authorized?
      unless Moderatorship.find_by_forum_id_and_user_id(params[:id], params[:user_id])
        Moderatorship.new do |m|
          m.forum_id = params[:id]
          m.user_id = params[:user_id]
          m.save
        end
      end
    else
      flash[:notice] = "You are not authorized to edit this forum!"
    end
    
    redirect_to :action => :list, :id => params[:id]
  end
  
  def list
    @auth_users = []
    Moderatorship.find_all_by_forum_id(params[:id], :order => 'user_id ASC').each do |u|
      @auth_users << u.user_id
    end
    
    @unauth_users = []
    User.find(:all, :order => 'id ASC').each do |u|
      @unauth_users << u.id unless @auth_users.include? u.id
    end
  end
  
protected
  def authorized?(forum_id = params[:id], user_id = current_user.id)
    Forums.find(forum_id).owner_id.to_i == user_id.to_i
  end
end
