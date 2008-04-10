class PolicyWizardController < ApplicationController
  before_filter :login_required
  before_filter :find_policy_auth, :except => [:show, :start, :create]
  
  def show
    redirect_to :action => :start
  end
  
  def start
    @policy = Policy._default(current_user)
    @policy.name = nil
  end

  def create
    @policy = Policy.new(params[:policy])
    
    if @policy.save
      redirect_to :action => :public, :id => @policy.id
    else 
      render :action => :start
    end
  end

  def public
    # render public.rhtml
  end

  def protected
    render :action => :public unless @policy.update_attributes(params[:policy])
  end

  def private
    render :action => :protected unless @policy.update_attributes(params[:policy])
  end

  def finish
    # render finish.rhtml
  end
  
  def permission
    # hack for javascript contributor selection form
    case params[:contributor_type].to_s
    when "User"
      contributor = User.find(params[:user_contributor_id])
    when "Network"
      contributor = Network.find(params[:network_contributor_id])
    else
      error("Invalid contributor type", "invalid type (must be User or Network)", :contributor_type)
    end
    
    @permission = Permission.new(:policy => @policy, :contributor => contributor, :view => params[:view], :download => params[:download], :edit => params[:edit])

    render :partial => "policies/permission", :object => @permission, :locals => { :read_only => true } if @permission.save
  end
  
protected
  
  def find_policy_auth
    @policy = Policy.find(:first, :conditions => ["id = ? AND contributor_id = ? AND contributor_type = ?", params[:id], current_user.id, "User"])
    
    error("Policy not found (id not authorized)", "is invalid (not owner)") unless @policy
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Policy.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to policies_url }
    end
  end
end
