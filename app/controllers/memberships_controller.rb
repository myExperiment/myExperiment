class MembershipsController < ApplicationController

  before_filter :login_required

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create ],
         :redirect_to => { :action => :list }

  def list
  end

  def create
    @profile = Profile.find_by_name(params[:profile][:name])
    if @profile
      @membership = Membership.new()
      @membership.project_id = params[:id];
      @membership.user_id = @profile.user.id
      if @membership.save
        flash[:notice] = "#{params[:profile][:name]} successfully added."
      else
        flash[:notice] = "#{params[:profile][:name]} already a member."
      end
    else
      flash[:notice] = "User '#{params[:profile][:name]}' not found."
    end
    redirect_to :controller => 'projects', :action => 'show', :id => params[:id]
  end

  def destroy
    Membership.find_by_project_id_and_user_id(params[:id], params[:member_id]).destroy
    redirect_to :controller => 'projects', :action => 'show', :id => params[:id]
  end
end
